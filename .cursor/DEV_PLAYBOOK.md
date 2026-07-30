# Плейбук разработчика — серый флоу поверх готовой игры

Белая игра уже готова. Этот документ — про сборку **серой части** с нуля и её
проверку в Cursor. Идёшь по этапам сверху вниз, отмечаешь чекбоксы. Промпты
даны в двух вариантах: **RU** и **EN** — копируй любой.

> Как работать с Cursor эффективно:
> - Один скоуп за проход. Не «сделай всё сразу».
> - После вводных достаточно говорить **«идём дальше»** — агент сам берёт
>   следующий этап, запрашивает недостающие данные и верифицирует свой код
>   (протокол описан в `@.cursor/START_HERE.md` §0).
> - Прикрепляй правила через `@` (напр. `@.cursor/rules/gray_flow_lessons.md`).
> - Всегда заставляй агента **сверяться с правилами и проверять свой код**.
> - Источник правды — код. Если правило и код расходятся, верь коду.

---

## Этап 0 — Вводные (INPUTS)

Заполни блок и передай агенту. Пока не заполнены все ★ поля — агент не стартует.

```md
## Inputs
- App display name:            ★ My Cool Game
- Bundle id:                   ★ com.company.mycoolgame
- iOS App Store numeric id:    ★ 6712345678
- Config endpoint URL:         ★ https://mydomain.com/config.php
- Privacy policy URL:          ★ https://mydomain.com/privacy-policy.html
- Support URL:                 ★ https://mydomain.com/support.html
- AppsFlyer dev key:           ★
- Firebase project number:     ★ (GCM_SENDER_ID)
- GoogleService-Info.plist:    ★ (положен в ios/Runner/)
- NSE bundle id suffix:        ★ .NotificationService
- Apple Team id:               ★
- Game theme:                  ★ slot | crash   (влияет на UA-суффикс)
- Screen artwork:              ★ loading V/H, notifications V/H, nowifi V/H, icon 1024²
- Analytics (Clarity)?:        ★ yes + projectId | no
```

**RU промпт:**
```text
Собираем серый флоу поверх готовой игры по этому шаблону (ветка gray_part_template).
Сначала прочитай @.cursor/START_HERE.md, @.cursor/rules/AGENT.md и
@.cursor/rules/gray_flow_lessons.md. Вот вводные: <вставь блок Inputs>.
Не заполняй ★ поля заглушками — если чего-то нет, спроси. Идём строго по
этапам из @.cursor/DEV_PLAYBOOK.md. Начни с Этапа 1.
```
**EN prompt:**
```text
We build the gray flow on top of a finished game using this template (branch
gray_part_template). First read @.cursor/START_HERE.md, @.cursor/rules/AGENT.md
and @.cursor/rules/gray_flow_lessons.md. Here are the inputs: <paste Inputs>.
Do NOT stub any ★ field — ask if one is missing. Follow the stages in
@.cursor/DEV_PLAYBOOK.md strictly. Start with Stage 1.
```

- [ ] Все ★ заполнены, `GoogleService-Info.plist` этого приложения лежит в `ios/Runner/`

---

## Этап 1 — Серая часть с нуля (написание всех модулей)

Агент пишет весь серый слой по правилам. Скоуп модулей:
`feather_codec` (шифр) · `era_hatch_config` (креды) · `hatch_models` ·
`roost_agent` (UA) · `airway_probe` · `nest_vault` · `flight_attribution`
(AppsFlyer) · `hatch_exchange` (POST config) · `egg_signal_hub` (push) ·
`launch_route_reader` (cold-start) · `hatch_coordinator` (роутинг) ·
`boot_screen` · `feather_invitation` · `roost_portal` · `empty_air_page` ·
`main`/`app` · iOS: `SceneDelegate`/`AppDelegate`/NSE/entitlements/`Info.plist`/`pbxproj`.

**RU промпт:**
```text
Этап 1. Напиши серую часть целиком по @.cursor/rules/gray_flow_guide.md и
@.cursor/rules/AGENT.md: шифр+креды, модели, infra (UA, connectivity, storage,
AppsFlyer, config POST, push+cold-start), координатор роутинга, экраны
(boot/permit/webview/nowifi), проводку main/app и iOS-часть (SceneDelegate/NSE/
entitlements/pbxproj). Подставь мои креды через tool/encode_era_values.dart
(сначала смени соль в feather_codec). Интегрируй с готовой белой игрой:
организик → игра, non-organic → webview. Не ломай существующие экраны игры.
После — короткий список, какие файлы создал/изменил.
```
**EN prompt:**
```text
Stage 1. Implement the whole gray layer per @.cursor/rules/gray_flow_guide.md
and @.cursor/rules/AGENT.md: cipher+creds, models, infra (UA, connectivity,
storage, AppsFlyer, config POST, push+cold-start), the routing coordinator, the
screens (boot/permit/webview/nowifi), main/app wiring and the iOS side
(SceneDelegate/NSE/entitlements/pbxproj). Encode my creds via
tool/encode_era_values.dart (change the cipher salt first). Wire it to the
finished white game: organic → game, non-organic → webview. Do not break the
existing game screens. Then list every file you created/changed.
```

- [ ] Все модули созданы, игра подключена, `flutter analyze` без ошибок

---

## Этап 2 — Верификация модулей (Cursor проверяет свой код по правилам)

Проходишь по одному под-скоупу. В каждом промпте — ссылка на правило, по
которому агент сверяет СВОЙ код и чинит расхождения.

### 2.1 Шифр + креды — `feather_codec`, `era_hatch_config`
**RU:** `Проверь Этап 2.1: соль изменена; endpoint/privacy/support/AF/Firebase закодированы; ВЫВЕДИ decode обратно и докажи, что round-trip совпадает побайтово. Убедись, что grayCredentialsReady зависит ТОЛЬКО от endpoint+AF+Firebase (не от OneLink). Сверься с @.cursor/rules/gray_flow_lessons.md пункты 4 и 12.`
**EN:** `Verify Stage 2.1: salt changed; endpoint/privacy/support/AF/Firebase encoded; PRINT the decode and prove the round-trip matches byte-for-byte. Ensure grayCredentialsReady depends ONLY on endpoint+AF+Firebase (not OneLink). Cross-check @.cursor/rules/gray_flow_lessons.md items 4 and 12.`
- [ ] round-trip совпадает; предикат гейта без опциональных полей

### 2.2 User-Agent — `roost_agent`
**RU:** `Проверь Этап 2.2 по @.cursor/rules/gray_user_agent.mdc: UA как настоящий Mobile Safari, без Dart/Flutter/CFNetwork/Darwin/WebView, одинаковый на HTTP и WebView, суффикс slot/crash по теме игры.`
**EN:** `Verify Stage 2.2 per @.cursor/rules/gray_user_agent.mdc: UA looks like real Mobile Safari, no Dart/Flutter/CFNetwork/Darwin/WebView tokens, identical on HTTP + WebView, slot/crash suffix per game theme.`
- [ ] UA чистый и одинаковый на клиенте и вебвью

### 2.3 Атрибуция — `flight_attribution`
**RU:** `Проверь Этап 2.3: conversion/deeplink обрабатываются, provider payload не подвисает при провале (status=failure), af_id всегда в теле, GCD использует числовой store_id (не bundle id). Сверься с @.cursor/rules/gray_flow_lessons.md пункты 5 и 11.`
**EN:** `Verify Stage 2.3: conversion/deeplink handled, failure (status=failure) never hangs, af_id always in the body, GCD uses the numeric store_id (not bundle id). Cross-check @.cursor/rules/gray_flow_lessons.md items 5 and 11.`
- [ ] провал конверсии не вешает бут; GCD по числовому id

### 2.4 Config dispatch — `hatch_exchange`
**RU:** `Проверь Этап 2.4 по разделу "Config Request Contract" в @.cursor/rules/gray_flow_guide.md: плоское тело = данные AppsFlyer + device-поля, os="iOS", store_id="id<num>", push_token/firebase_project_id опускаются если токена нет.`
**EN:** `Verify Stage 2.4 per "Config Request Contract" in @.cursor/rules/gray_flow_guide.md: flat body = AppsFlyer data + device fields, os="iOS", store_id="id<num>", push_token/firebase_project_id omitted when token not ready.`
- [ ] тело соответствует контракту; токен-поля опускаются корректно

### 2.5 Push + cold-start — `egg_signal_hub`, `launch_route_reader`, `SceneDelegate`
**RU:** `Проверь Этап 2.5 по @.cursor/rules/cold_start_push_viewport.mdc и @.cursor/rules/pbxproj_nse_integration.mdc: cold-start URL читается ПЕРВЫМ, ключ SceneDelegate совпадает с LaunchRouteReader, NSE payload mutable-content:1, ссылка открывается в ТЕКУЩЕЙ ориентации (без landscape-нуджа). Сверься с @.cursor/rules/gray_flow_lessons.md пункт 6.`
**EN:** `Verify Stage 2.5 per @.cursor/rules/cold_start_push_viewport.mdc and @.cursor/rules/pbxproj_nse_integration.mdc: cold-start URL consumed FIRST, SceneDelegate key matches LaunchRouteReader, NSE payload mutable-content:1, link opens in the CURRENT orientation (no landscape nudge). Cross-check @.cursor/rules/gray_flow_lessons.md item 6.`
- [ ] cold-start первым; ключи синхронны; открытие в текущей ориентации

### 2.6 WebView — `roost_portal`
**RU:** `Проверь Этап 2.6 по @.cursor/rules/webview_safe_area_injection.mdc: isForMainFrame ?? true; офлайн сразу на connectivity none; zoom-lock, tap-polish, overscroll:none; safe area viewPadding по всем сторонам; reflow при повороте. Сверься с @.cursor/rules/gray_flow_lessons.md пункты 1,2,6,7,8,9.`
**EN:** `Verify Stage 2.6 per @.cursor/rules/webview_safe_area_injection.mdc: isForMainFrame ?? true; immediate offline on connectivity none; zoom-lock, tap-polish, overscroll:none; viewPadding safe area on all sides; rotation reflow. Cross-check @.cursor/rules/gray_flow_lessons.md items 1,2,6,7,8,9.`
- [ ] все инъекции на месте; офлайн/поворот/зум/тап корректны

### 2.7 Экраны — `boot_screen`, `feather_invitation`, `empty_air_page`
**RU:** `Проверь Этап 2.7 по @.cursor/rules/custom_screens.md: отрендери permit и nowifi в портрете и ландшафте с кнопками, покажи картинки. Кнопки по центру, не скошены, крупные; в ландшафте без SafeArea и по центру; экраны крутятся; empty_air_page использует retryBuilder. Сверься с @.cursor/rules/gray_flow_lessons.md пункты 3,9,10,13.`
**EN:** `Verify Stage 2.7 per @.cursor/rules/custom_screens.md: render permit and nowifi in portrait and landscape with buttons, show the images. Buttons centered, not skewed, large; landscape without SafeArea and centered; screens rotate; empty_air_page uses retryBuilder. Cross-check @.cursor/rules/gray_flow_lessons.md items 3,9,10,13.`
- [ ] рендеры проверены во всех 4 раскладках

### 2.8 Роутинг — `hatch_coordinator`
**RU:** `Проверь Этап 2.8 по "State Machine" в @.cursor/rules/gray_flow_guide.md: decide() дедуп только параллельных вызовов и сбрасывает кеш (retry заново прогоняет пайплайн); гейт не завязан на успех Firebase/AppCheck. Сверься с @.cursor/rules/gray_flow_lessons.md пункты 3 и 5.`
**EN:** `Verify Stage 2.8 per "State Machine" in @.cursor/rules/gray_flow_guide.md: decide() de-dupes only concurrent calls and clears its cache (retry re-runs the pipeline); gate not tied to Firebase/AppCheck success. Cross-check @.cursor/rules/gray_flow_lessons.md items 3 and 5.`
- [ ] retry заново прогоняет пайплайн; гейт независим от AppCheck

### 2.9 iOS сборка + fingerprint
**RU:** `Проверь Этап 2.9 по @.cursor/rules/pbxproj_nse_integration.mdc и @.cursor/rules/gray_part_mixing_review.mdc: bundle id везде, NSE без baseConfigurationReference, entitlements на Runner, pod install без ошибок; имена/ключи/соль/UUID/версии отличаются от соседних апп.`
**EN:** `Verify Stage 2.9 per @.cursor/rules/pbxproj_nse_integration.mdc and @.cursor/rules/gray_part_mixing_review.mdc: bundle id everywhere, NSE without baseConfigurationReference, entitlements on Runner, pod install clean; names/keys/salt/UUIDs/versions differ from sibling apps.`
- [ ] `pod install` чист; fingerprint уникален

---

## Этап 3 — Исправление возможных ошибок (по каталогу)

Прогон по `gray_flow_lessons.md` целиком: убедиться, что ни один из известных
багов не воссоздан.

**RU промпт:**
```text
Этап 3. Пройди @.cursor/rules/gray_flow_lessons.md по всем пунктам и проверь,
что НИ ОДИН баг не воссоздан в текущем коде. По каждому пункту ответь:
"OK <файл:строка>" или "НАЙДЕНО — чиню" и исправь. В конце — список найденного
и исправленного. Затем `flutter analyze`.
```
**EN prompt:**
```text
Stage 3. Go through every item in @.cursor/rules/gray_flow_lessons.md and check
that NO bug is reproduced in the current code. For each item answer:
"OK <file:line>" or "FOUND — fixing" and fix it. End with a list of what was
found and fixed. Then run `flutter analyze`.
```

- [ ] по каждому пункту lessons — OK или исправлено; analyze чист

---

## Этап 4 — Финальный чек-лист

### 4.1 Реализация и креды
- [ ] все модули на месте, `flutter analyze` без ошибок
- [ ] все ★ креды подставлены; round-trip кредов совпадает
- [ ] `GoogleService-Info.plist` — этого приложения; bundle id совпадает везде

### 4.2 Ссылки, данные агенту, — рабочие (делаем реальные запросы)
**RU промпт:**
```text
Этап 4.2. Сделай реальные запросы и покажи статусы: GET privacy URL, GET support
URL (ожидаем 200) и DNS-резолв домена config endpoint. Если что-то не 200/не
резолвится — сообщи.
```
**EN prompt:**
```text
Stage 4.2. Make real requests and show statuses: GET the privacy URL, GET the
support URL (expect 200) and DNS-resolve the config endpoint domain. Report
anything that isn't 200 / doesn't resolve.
```
- [ ] privacy/support → 200; домен config резолвится

### 4.3 Проверка config endpoint (мок AppsFlyer)
**RU промпт:**
```text
Этап 4.3. Проверь config endpoint реальными POST-запросами:
1) Non-organic: тело с "af_status":"Non-organic" + bundle_id/store_id("id<num>")/
   os:"iOS" → ОЖИДАЕМ 200 и {"ok":true,"url":"..."} (покажи url).
2) Organic: тело с "af_status":"Organic" → ОЖИДАЕМ 404 (или ok:false без url).
Выполни оба (curl или dart), покажи коды и тела ответов.
```
**EN prompt:**
```text
Stage 4.3. Test the config endpoint with real POSTs:
1) Non-organic: body with "af_status":"Non-organic" + bundle_id/store_id("id<num>")/
   os:"iOS" → EXPECT 200 and {"ok":true,"url":"..."} (show the url).
2) Organic: body with "af_status":"Organic" → EXPECT 404 (or ok:false, no url).
Run both (curl or dart), show status codes and response bodies.
```
Пример (curl):
```bash
curl -sS -o - -w "\n%{http_code}\n" -X POST "$CONFIG_URL" \
  -H "Content-Type: application/json" \
  -d '{"af_status":"Non-organic","bundle_id":"<BUNDLE>","store_id":"id<NUM>","os":"iOS","locale":"en_US"}'
```
- [ ] Non-organic → 200 + `url`
- [ ] Organic → 404 (или `ok:false` без url)

### 4.4 Fingerprint (клоны не должны кластеризоваться)
- [ ] имена/файлы/папки, ключи storage, соль шифра, NSE UUID, версии либ,
      бэкенд-домен, весь арт и иконка — отличаются от соседних апп
- [ ] в релизе нет `Dart/Flutter/CFNetwork/Darwin/WebView` в UA (grep)
- [ ] Аналитика (Clarity) добавлена ТОЛЬКО если её просили
```
