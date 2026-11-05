# Что можно улучшить

Здесь собраны находки, которые обнаружились при импорте. Импорт делали «как есть», поэтому
ничего из списка ещё не сделано. Каждый пункт — отдельное изменение через репо: правка
кода, `plan`, `apply`.

Приоритет: 🔴 безопасность или риск потерять данные · 🟡 надёжность и порядок · ⚪ косметика.

## Секреты и доступ

- 🔴 **Cloud Run `noxapp`: секреты в env открытым текстом.** `DRIVE_OAUTH_CLIENT_SECRET`,
  `DRIVE_OAUTH_REFRESH_TOKEN` и `AGENT_PUSH_TOKEN` видны всем, у кого есть `run.services.get`
  (это в том числе `roles/viewer`), и лежат в Terraform state. Решение: перенести в Secret
  Manager (API пока не включён), в сервисе ссылаться на них через `value_source.secret_key_ref`.
  После этого env можно описать в коде и убрать из `ignore_changes`.
- 🔴 **Scheduler `noxapp-sync-images` передаёт токен в URL** (`/sync-images?token=…`). URL
  с токеном оседает в логах Scheduler и Cloud Run. Решение: `oidc_token` от отдельного SA
  и проверка вызывающего на стороне Cloud Run (IAM invoker). Тогда токен в URL не нужен.
- 🔴 **Cloud Run `noxapp` публичный, IAM при вызове не проверяется** (`invoker_iam_disabled = true`,
  ingress `ALL`). Нужно понять, кому сервис должен быть доступен снаружи (push от агента?).
  Закрыть всё, что можно закрыть.
- 🔴 **Default compute SA `99257183987-compute@` с `roles/editor` в `thermal-history`.** От
  его имени работают и VM `instance-1`, и Cloud Run `noxapp`. Плюс у него `datastore.owner`
  в `noxapp-39eee`. Если взломают VPN-сервер, получат editor на весь проект. Решение: дать VM
  и Cloud Run по отдельному SA с минимальными ролями (Cloud Run: `datastore.user` в noxapp,
  доступ к Sheets и Drive), у default SA роль `editor` снять.
- 🔴 **Ключи сервисных аккаунтов.** У `terraform-alex` (editor, ключ от 2025-06),
  `cert-manager-dns01` (dns.admin, ключ от 2025-06), `noxapp-play-publisher` (ключ от
  2026-08) и `claude-agent`. Нужно выяснить, где используется каждый ключ, ротировать живые
  и удалить ненужные. Ключи в Terraform не импортируются, их видно только в
  `gcloud iam service-accounts keys list`.
- 🟡 **`terraform-alex` (editor), «For using to apply terraform for alex».** Похоже, остался
  от прошлой попытки описать инфраструктуру. Если не используется, удалить вместе с ключом.
- 🟡 **`cert-manager-dns01` с `dns.admin` на всю зону.** Используется cert-manager где-то
  вне этих проектов. Выяснить где, по возможности перейти на Workload Identity без ключа.
- 🟡 **noxapp: `datastore.owner` у compute SA.** Для записи хватит `roles/datastore.user`.
  Решается вместе с отдельным SA для Cloud Run (см. выше).
- 🟡 **noxapp: Android API-ключ без ограничений по приложению.** Добавить package name
  `com.nox73.noxapp` и SHA-1 подписи (нужен сертификат из Play Console или keystore).
- 🟡 **noxapp: Browser API-ключ.** Веб-приложений нет, ключ, скорее всего, лишний.
  Удалить.
- ⚪ **`claude-agent` с ролью `iam.securityAdmin`** фактически равен владельцу. Если
  появится CI, давать ему права через WIF, а у агента в контейнере оставить только чтение.

## VM `instance-1` (Outline VPN)

- 🔴 **У VM нет бэкапов.** Расписание снапшотов `default-schedule-1` ни к одному диску не
  привязано. Последний снапшот `instance-2-…-20260706` сделан с диска уже удалённой VM. Решение:
  привязать расписание к диску `instance-1` (`google_compute_disk_resource_policy_attachment`),
  а старый снапшот удалить, если он не нужен.
- 🟡 **Ubuntu 20.04 (focal)**: стандартная поддержка закончилась в апреле 2025. Нужно
  переехать на 24.04, проще всего пересоздать VM: Outline переустанавливается быстро, IP
  статический.
- 🟡 **`deletion_protection = false`, Secure Boot выключен.** Включить и то и другое.
- 🟡 **Project metadata `ssh-keys` с ключом `root@0fb141054fd5`**, хотя `enable-oslogin=TRUE`.
  При включённом OS Login ключи из метаданных игнорируются, так что этот ключ — мусор.
  Удалить.

## Сеть и DNS

- 🟡 **Firewall-правила.** В `default-allow-ssh` разрешён `udp:22` (бессмысленно), а
  description «Allow SSH from anywhere» вводит в заблуждение. `ssh23` открывает `tcp:23`:
  выяснить, нужен ли он ещё. `default-allow-icmp` открыт для `0.0.0.0/0`. Почистить и
  описать каждое правило.
- 🟡 **DNSSEC для `nox73.com` выключен.** Включить: зона в Cloud DNS, домен в Google
  Domains / Squarespace, DS-запись добавляется у регистратора.
- ⚪ **`v.nox73.com` делегирован в другую зону Cloud DNS** (`ns-cloud-b*`). Эта зона живёт в
  GCP-проекте `noxvpn-skv384` (проект noxvpn), его пока нет ни в скоупе, ни в доступах
  `claude-agent`. Когда будем брать noxvpn в работу: выдать агенту доступ, импортировать зону
  и описать связь (NS-запись в `nox73` ↔ зона `v.nox73.com` в `noxvpn-skv384`).
- ⚪ **Connectivity tests `ssh-troubleshoot-*` (4 шт., 2022–2024).** Это мусор от отладки
  SSH в консоли, удалить.
- ⚪ **Default VPC в auto mode** (40+ подсетей во всех регионах), а используется одна
  подсеть. Позже можно перейти на custom-mode VPC с одной подсетью. Это переезд VM, так что
  делать вместе с обновлением ОС.

## Cloud Run и сборки

- 🟡 **Artifact Registry `cloud-run-source-deploy` без cleanup policy.** Образы копятся (их уже
  29). Добавить политику «хранить последние N».
- 🟡 **Бакет `run-sources-…` без lifecycle.** Архивы исходников от каждого деплоя копятся.
  Добавить удаление через 30–90 дней.
- ⚪ **Деплой `noxapp` из консоли** (`client = cloud-console`). Лучше перенести в CI
  или в скрипт в репо приложения, чтобы было видно, какой коммит задеплоен.

## noxapp (Firebase)

- 🟡 **Firestore: `delete_protection_state` выключен, PITR выключен.** Включить защиту от
  удаления. PITR платный, а billing у проекта нет, так что решить отдельно.

## Billing и общее

- 🟡 **Нет budget-алертов** (API `billingbudgets` включён, но бюджетов нет). Завести бюджет
  с алертами на USD-аккаунт (`google_billing_budget`).
- ⚪ **RUB Billing Account `01F31D-…` открыт, но к нему не привязан ни один проект.**
  Закрыть, если не нужен.
- ⚪ **Лишние API.** В `thermal` и `noxapp` включено по 40 API, большинство включились
  автоматически (BigQuery, backupdr, …). В Terraform описаны только используемые. Остальные
  можно выключить, но сначала проверить, что от них ничего не зависит.
- ⚪ **`talktruly`.** Пустой проект, оставлен как есть по решению. Вернуться позже: удалить
  или начать использовать.
