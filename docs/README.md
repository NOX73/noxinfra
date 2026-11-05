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
| `setup.sh` | postCreate: версии инструментов, проверка `.gitignore`, ключ SA, активация SA в gcloud, предупреждение о личном аккаунте |
| `isolate.sh` | postAttach: убирает проброшенные с хоста ssh-agent и git credential helper |

**Инструменты:** Terraform 1.17.1, tflint 0.65.0, Google Cloud CLI, sops 3.13.3,
age 1.3.2, yq 4.54.1, shellcheck, jq, git, make. Бинарники с GitHub/HashiCorp проверяются
по SHA256. Есть алиас `tf=terraform` и автодополнение для terraform и gcloud.

**Решения:**

- **Всё состояние оператора лежит на волюме `noxinfra-home` (смонтирован в `/root`):**
  конфиг gcloud и ключ SA, кэш провайдеров Terraform (`TF_PLUGIN_CACHE_DIR`), история
  shell, состояние Claude Code (`~/.claude`, `~/.claude.json`). В noxvpn история Claude
  монтировалась с хоста, здесь — нет: она живёт только на волюме и переживает пересборку
  контейнера. Полный сброс — `docker volume rm noxinfra-home`.
- **Репо смонтировано по тому же абсолютному пути, что на хосте.** Пути в логах, планах и
  сессиях Claude совпадают.
- **В контейнере работает только сервисный аккаунт `claude-agent`.** В контейнере работает
  агент (Claude Code), а всё, что лежит на волюме, ему доступно. Поэтому личным аккаунтом там
  не логинимся, в контейнере лежит только ключ SA: `/root/.config/gcloud/claude-agent.json` на
  волюме, в репо его нет. Его же через `GOOGLE_APPLICATION_CREDENTIALS` использует
  Terraform. `CLOUDSDK_CORE_PROJECT` не задан, проект всегда указывается явно.
  - SA создан в `thermal-history-343013`. Там же включены API, которые идут на его квоту
    (`cloudasset`, `cloudresourcemanager`, `serviceusage`, `iam`, `cloudbilling`), и выдана
    роль `serviceusage.serviceUsageConsumer`.
  - Проекты в скоупе (`thermal-history-343013`, `noxapp-39eee`): `roles/editor` и
    `roles/iam.securityAdmin`. Этого хватает для `apply`, включая IAM-биндинги. Владельцем
    проекта SA не сделан, поэтому удалить проект напрямую не может. Но через
    `securityAdmin` он может выдать себе любую роль, так что фактически это права уровня
    владельца.
  - Остальные проекты: только чтение (`roles/viewer`, `roles/iam.securityReviewer`,
    `roles/cloudasset.viewer`).
  - Открытые billing-аккаунты: `roles/billing.viewer`.
  - Ключ создаётся на хосте и копируется в контейнер:
    `docker cp key.json $(docker ps -q --filter label=devcontainer.local_folder=$PWD):/root/.config/gcloud/claude-agent.json`.
    После этого копию на хосте нужно удалить. Ключ стоит периодически ротировать.
- **Ограничитель для агента: `.claude/settings.json`.** Правила `ask` для разрушающих
  команд: `terraform apply/destroy/import/state rm|mv|push/force-unlock` (в том числе
  через `tf`, `-chdir=` и `make apply|destroy`), `gcloud … delete|disable`,
  `gcloud … *-iam-policy*`, `gcloud storage rm`, `gsutil rm|rb`. Такие команды агент
  выполняет только после подтверждения человеком. Это защита от ошибки, а не граница
  безопасности: у SA есть права на запись.
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
2. Ключ SA должен лежать в `/root/.config/gcloud/claude-agent.json` (см. выше). Личным
   аккаунтом в контейнере не логиниться.
3. `bash .devcontainer/setup.sh` — проверка, что всё на месте. Если SA ещё не активирован
   в gcloud, скрипт его активирует.

## Что предстоит

### 1. Репозиторий
- [x] `git init`, первый коммит, remote (`github.com:NOX73/noxinfra`).

### 2. Инвентаризация GCP
- [x] Список проектов: организации нет, все проекты «бездомные».
  `gen-lang-client-0948610743` (Default Gemini Project), `noxapp-39eee` (Firebase),
  `talktruly`, `thermal-history-343013` (основные ресурсы: VM, VPC, Cloud Run, DNS,
  Artifact Registry).
- [x] Billing-аккаунты: `01C100-B62CB3-89CCC4` (USD, к нему привязан
  `thermal-history-343013`), `01F31D-A21EE0-6CD6CC` (RUB, проекты не привязаны),
  `007304-975A5D-1651C9` (закрыт). У остальных проектов billing не подключён.
- [x] Скоуп: `thermal-history-343013` и `noxapp-39eee`. По `talktruly` и
  `gen-lang-client-0948610743` решение отложено.
- [ ] По каждому проекту — включённые API и все ресурсы:
  `gcloud services list --enabled --project=P`,
  `gcloud asset search-all-resources --scope=projects/P` (нужен API `cloudasset.googleapis.com`).
- [ ] Решить по каждому ресурсу: импортировать, удалить как мусор или оставить вне Terraform
  (с причиной).

### 3. Remote state
- [x] Проект-«админка» для state: `thermal-history-343013` (там же живёт SA).
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
- Нужны ли секреты в репо (тогда sops + age) или всё держим в Secret Manager.
- Судьба `talktruly` и `gen-lang-client-0948610743`: импортировать, удалить или оставить вне Terraform.
