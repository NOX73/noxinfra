# Удалённые ресурсы

Что удалили из облака, что от этого осталось и как вернуть.

## VM `instance-1` (Outline VPN) — удалена 2026-11-20

Проект `thermal-history-343013`. На VM работал Outline VPN-сервер, адрес
`nl.outline.nox73.com`. Её погасили, чтобы не платить (около $10 в месяц за VM и IP).
Сохранили только бэкап диска в самом дешёвом виде.

### Что удалено

| Ресурс | Подробности |
|---|---|
| VM `instance-1` | `e2-micro`, `europe-west4-a`, Ubuntu 20.04 minimal (`ubuntu-minimal-2004-focal-v20220331`). Внутренний IP `10.164.0.4`, SA `99257183987-compute@developer.gserviceaccount.com`, OS Login, лейбл `goog-ops-agent-policy=v2-template-1-5-0` |
| Диск `instance-1` | Загрузочный, `pd-balanced`, 10 ГБ. Удалён вместе с VM (`auto_delete`) |
| Статический IP `outline-v2-static-standard-tier` | `35.214.243.249`, `europe-west4`, Standard tier. **Вернуть этот адрес нельзя** |
| DNS `nl.outline.nox73.com. A` | Указывал на `35.214.243.249`, TTL 300 |
| `35.214.243.249` в `source_ranges` | Убран из firewall-правил `default-allow-ssh` и `ssh23` |
| Снапшот `instance-2-europe-west4-a-20260706043600-phuxavvd` | Старый снапшот (4.2 ГБ, multi-region `eu`) с диска давно удалённой VM `instance-2`. Не был в Terraform, удалён через `gcloud` |

До удаления VM остановили, чтобы снапшот был консистентным.

### Что осталось: бэкап диска

Снапшот `instance-1-final-20261120`. Описан в
[`gcp/thermal-history-343013/vm.tf`](../gcp/thermal-history-343013/vm.tf)
(`google_compute_snapshot.instance_1_final`, `prevent_destroy`).

- Тип `ARCHIVE`, хранится в регионе `europe-west4`, 3.9 ГБ данных (размер диска 10 ГБ).
- Стоимость около $0.08 в месяц. У archive-снапшотов минимальный срок оплаты 90 дней:
  если удалить раньше, всё равно спишут за 90 дней. При восстановлении берут плату за
  извлечение (около $0.02/ГБ, то есть около $0.08 за одно восстановление).
- На диске всё состояние Outline (`/opt/outline`: ключи доступа, конфиг сервера).

### Как восстановить

1. Создать диск из снапшота (тип и размер те же, что были):
   ```sh
   gcloud compute disks create instance-1 --project thermal-history-343013 \
     --zone europe-west4-a --type pd-balanced --size 10 \
     --source-snapshot instance-1-final-20261120
   ```
   Правильнее сделать то же в Terraform: `google_compute_disk` с
   `snapshot = google_compute_snapshot.instance_1_final.self_link`.
2. Зарезервировать новый статический IP (старый `35.214.243.249` потерян): регион
   `europe-west4`, Standard tier (`google_compute_address`).
3. Создать VM с этим диском в качестве загрузочного (`boot_disk { source = ... }`).
   Параметры как раньше: `e2-micro`, `europe-west4-a`, сеть `default`, `access_config` с
   новым IP. **SA тот же**: `99257183987-compute@`. Firewall-правила `outline`
   (tcp/udp 443, 1640, 38014) и `ssh23` нацелены на этот SA, с другим SA они работать не
   будут. Политика, которая ставила Ops Agent, удалена 2026-11-21; если агент нужен, его
   придётся ставить заново (и помнить, что его метрики платные сверх 150 МиБ на аккаунт).
   Прежнюю конфигурацию VM можно взять из git:
   `git show <коммит до удаления>:gcp/thermal-history-343013/vm.tf`.
4. Вернуть A-запись `nl.outline.nox73.com` с новым IP (`google_dns_record_set` в
   [`dns.tf`](../gcp/thermal-history-343013/dns.tf)). При желании вернуть новый IP в
   `source_ranges` правил `default-allow-ssh` и `ssh23`.
5. Outline: если в ключах доступа указан hostname `nl.outline.nox73.com`, после
   обновления DNS они заработают сами. Если в ключах IP, их придётся перевыпустить. Какой
   из вариантов, видно по полю `hostname` в
   `/opt/outline/persisted-state/shadowbox_server_config.json`.
6. Ubuntu 20.04 уже без стандартной поддержки. Если VM нужна надолго, лучше поставить
   новую VM на 24.04 и перенести на неё Outline (или переустановить его), а не поднимать
   старый диск.

Когда бэкап станет не нужен: убрать `prevent_destroy` и ресурс из `vm.tf`, затем
`terraform apply`. Но раньше 2027-02-18 (90 дней) удалять смысла нет, деньги за этот
срок всё равно спишут.

### Бесплатные остатки

Политику Ops Agent (`goog-ops-agent-v2-template-1-5-0-europe-west4-a`) удалили
2026-11-21: VM в проекте нет, она ни на что не действовала.

Эти ресурсы остались после VM. Ничего не стоят, ничего не делают, всё ещё в Terraform.
Их оставили, чтобы восстановление было проще. Если VM не понадобится, можно удалить.

| Ресурс | Где в коде | Что это |
|---|---|---|
| Firewall `outline` | [`network.tf`](../gcp/thermal-history-343013/network.tf) | Открывает Outline-порты (tcp/udp 443, 1640, 38014) из `0.0.0.0/0` для VM с SA `99257183987-compute@`. Сейчас таких VM нет |
| Firewall `ssh23` | [`network.tf`](../gcp/thermal-history-343013/network.tf) | `tcp:23` для того же SA, был нужен VM |
| Расписание снапшотов `default-schedule-1` | [`vm.tf`](../gcp/thermal-history-343013/vm.tf) | Еженедельно по воскресеньям, хранение 20 дней. Ни к одному диску не привязано |
| Метаданные проекта `enable-oslogin`, `ssh-keys` | [`vm.tf`](../gcp/thermal-history-343013/vm.tf) | Действуют на все VM проекта. `ssh-keys` и так мусор (при OS Login игнорируется) |

Firewall-правила `default-allow-*` и default VPC к VM не относятся, они общие для
проекта.
