# noxinfra

Terraform-описание всех моих облачных ресурсов. Цель — один репозиторий, через который
делаются все изменения в облаке.

## Цель и принципы

- **Начинаем с GCP.** Там несколько проектов с ресурсами, созданными вручную (консоль, gcloud).
  Их нужно описать в Terraform и импортировать в state, ничего не пересоздавая.
- **После импорта меняем только через репо.** Правки в консоли запрещены. Если что-то
  поменяли руками, это дрейф, который виден в `terraform plan` и устраняется кодом.
- **Потом другие облака.** Структура репо должна позволить добавить их рядом с GCP.
- **Вся работа идёт в devcontainer.** Инструменты закреплены по версиям, учётные данные
  и состояние оператора на хост не попадают.

## Что сделано

### Devcontainer (`.devcontainer/`)

Основа — devcontainer из проекта noxvpn, адаптированный под Terraform + GCP.

| Файл | Назначение |
|---|---|
| `devcontainer.json` | Конфигурация контейнера, маунты, переменные окружения, расширения VS Code |
| `Dockerfile` | `debian:bookworm-slim` + закреплённые инструменты |
| `setup.sh` | postCreate: версии инструментов, проверка `.gitignore`, статус авторизации gcloud/ADC |
| `isolate.sh` | postAttach: убирает проброшенные с хоста ssh-agent и git credential helper |

**Инструменты:** Terraform 1.17.1, tflint 0.65.0, Google Cloud CLI, sops 3.13.3,
age 1.3.2, yq 4.54.1, shellcheck, jq, git, make. Бинарники с GitHub/HashiCorp проверяются
по SHA256. Есть алиас `tf=terraform` и автодополнение для terraform и gcloud.

**Решения:**

- **Всё состояние оператора лежит на волюме `noxinfra-home` (смонтирован в `/root`):**
  учётные данные gcloud и ADC, кэш провайдеров Terraform (`TF_PLUGIN_CACHE_DIR`), история
  shell, состояние Claude Code (`~/.claude`, `~/.claude.json`). В noxvpn история Claude
  монтировалась с хоста, здесь — нет: она живёт только на волюме и переживает пересборку
  контейнера. Полный сброс — `docker volume rm noxinfra-home`.
- **Репо смонтировано по тому же абсолютному пути, что на хосте.** Пути в логах, планах и
  сессиях Claude совпадают.
- **Авторизация — личный аккаунт, без ключей сервисных аккаунтов.** Проектов несколько, а
  ключ SA привязан к одному проекту, поэтому `CLOUDSDK_CORE_PROJECT` и
  `GOOGLE_APPLICATION_CREDENTIALS` не заданы. Вход: `gcloud auth login --update-adc` —
  одна команда и для gcloud, и для Terraform.
- **Изоляция от хоста:** нет docker socket и docker CLI, нет проброшенного ssh-agent, нет
  host git credential helper. Для Terraform это не нужно, а доступ к хосту меньше.
- **`config-connector` не ставится на arm64.** Пакет `google-cloud-cli-config-connector`
  нужен для `gcloud resource-config bulk-export --resource-format=terraform`, но для arm64
  его нет. Сборка при этом не падает, а основной путь импорта от него не зависит (см. ниже).

### `.gitignore`

Исключены: tfstate и бэкапы, `.terraform/`, `*.tfplan`, `terraform.tfvars` /
`*.auto.tfvars` (кроме `*.example.tfvars`), override-файлы, ключи (`*.key`, `*.pem`, `*.age`),
`secrets/`, `local/`, `.env*` и `generated/` — папка для черновиков HCL до того, как они
вычищены и перенесены в настоящий код.

## Как начать работу

1. VS Code → «Reopen in Container».
2. В терминале контейнера: `gcloud auth login --update-adc`.
3. `bash .devcontainer/setup.sh` — проверка, что всё на месте и авторизация есть.

## Что предстоит

### 1. Репозиторий
- [ ] `git init`, первый коммит, remote.

### 2. Инвентаризация GCP
- [ ] Список проектов и billing-аккаунтов: `gcloud projects list`, `gcloud billing accounts list`.
  Выяснить, есть ли организация или проекты «бездомные» (личный аккаунт).
- [ ] По каждому проекту — включённые API и все ресурсы:
  `gcloud services list --enabled --project=P`,
  `gcloud asset search-all-resources --scope=projects/P` (нужен API `cloudasset.googleapis.com`).
- [ ] Решить по каждому ресурсу: импортировать, удалить как мусор или оставить вне Terraform
  (с причиной).

### 3. Remote state
- [ ] Выбрать проект-«админку» для state (существующий или новый).
- [ ] GCS-бакет с версионированием и uniform bucket-level access. Создаётся вручную
  (курица и яйцо), затем импортируется в Terraform сам.

### 4. Структура репозитория
- [ ] Предварительно: отдельный root module (и отдельный state) на каждый GCP-проект плюс
  общий `modules/`. Например:
  ```
  gcp/
    _bootstrap/     # бакет state, сам проект-админка
    <project-a>/
    <project-b>/
  modules/
  ```
- [ ] Закрепить версии провайдеров (`google`, `google-beta`), коммитить `.terraform.lock.hcl`.
- [ ] `.tflint.hcl` с google ruleset, `Makefile` с целями `fmt` / `validate` / `lint` / `plan`.

### 5. Импорт
- [ ] Основной путь — нативные `import {}` блоки +
  `terraform plan -generate-config-out=generated.tf`. Сгенерированный HCL вычистить
  (убрать дефолты и computed-поля), разложить по файлам.
- [ ] Критерий готовности проекта: `terraform plan` показывает **No changes**.
- [ ] Порядок: начать с самого простого проекта, на нём отладить процесс.

### 6. Эксплуатация
- [ ] Регулярный `terraform plan` по всем проектам для поиска дрейфа.
- [ ] Позже, возможно: CI (GitHub Actions + Workload Identity Federation, без ключей SA).
- [ ] Позже: другие облака.

## Открытые вопросы
- Какие именно GCP-проекты входят в скоуп и какой из них станет админкой для state.
- Нужны ли секреты в репо (тогда sops + age) или всё держим в Secret Manager.
