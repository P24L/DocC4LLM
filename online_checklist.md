# Online DocC PoC Checklist

## 1. Prozkoumat online DocC dokumentaci
- [x] Ověřit dostupnost hlavní stránky dokumentace: https://atprotokit.cjrriley.com/documentation/atprotokit/
- [x] Ověřit metadata: https://atprotokit.cjrriley.com/metadata.json
- [x] Ověřit seznam všech dokumentačních souborů (index): https://atprotokit.cjrriley.com/data/documentation/atprotokit.json
- [x] Ověřit příklad konkrétní stránky dokumentace (APIClientService): https://atprotokit.cjrriley.com/data/documentation/atprotokit/atprotokit/apiclientservice.json
- [x] Ověřit příklad konkrétní stránky dokumentace (getPreferences()): https://atprotokit.cjrriley.com/data/documentation/atprotokit/atprotokit/getpreferences().json

## 2. Porovnání s .doccarchive strukturou
- [x] Porovnat URL schéma online dokumentace s cestami v .doccarchive
- [x] Ověřit, zda jsou všechny potřebné soubory dostupné online
- [x] Ověřit, zda je struktura (adresáře, reference) podobná .doccarchive

## 3. Úprava načítání dokumentace v DocCArchive
- [x] Najít v kódu místo, kde se načítají soubory z disku
- [x] Navrhnout rozhraní pro načítání z URL
- [x] Ošetřit cachování a opakované stahování (zatím PoC, bez cache)

## 4. Implementace a testování
- [x] Vytvořit downloader pro hlavní index a rekurzivní stahování (PoC: HTTPFileProvider)
- [x] Ověřit kompatibilitu s exportem (ověřeno na lokálním archivu)
- [x] Otestovat na části online dokumentace
- [x] Otestovat na celé online dokumentaci (rekurze, správné cesty, filtrace neexistujících/externích URL)
  - [x] Rekurze nyní přesně odpovídá SPA logice: prochází pouze reference z hlavního indexu (stejně jako Vue.js DocC)

## 5. Otevřené otázky
- [x] Jsou všechny potřebné JSON soubory veřejně dostupné?
- [x] Je struktura online dokumentace stabilní?
- [x] Jak řešit limity a změny URL schématu?
- [x] Jak ošetřit chybějící data?

---

## Shrnutí problému
- Problém byl v tom, že rekurze a hledání JSON souborů začínaly ve špatném adresáři (`documentation` místo `data/documentation`).
- Po opravě začátku rekurze a správném mapování cest je export plně funkční.
- Přidána filtrace cest: zpracovávají se pouze cesty začínající na `data/documentation/` (prefix parametrizovat do budoucna).
- Neúspěšné nebo externí URL jsou logovány a ignorovány.
- **Rekurze nyní odpovídá chování Vue.js SPA DocC: exportér načítá pouze reference z hlavního indexu, v failed_urls.txt zůstávají jen skutečně externí nebo explicitně chybějící soubory.**

## 6. Rozšířené URL podpory
- [x] **Index.json handling** - Automatické přesměrování z `/index/index.json` na hlavní modul dokumentace
  - [x] Implementován parsing `interfaceLanguages.swift[0].path` z index souboru
  - [x] Testováno na https://sdwebimage.github.io/index/index.json → data/documentation/sdwebimage.json
  - [x] Úspěšný export 293 dokumentačních souborů (598KB)
- [x] **Univerzální URL parsing** - Podpora všech tří hlavních use-cases:
  - [x] Přímé dokumenty: `https://sdwebimage.github.io/data/documentation/sdwebimageswiftui.json`
  - [x] Vnořené dokumenty: `https://atprotokit.cjrriley.com/data/documentation/atprotokit/atprotokit/apiclientservice.json`
  - [x] Index dokumenty: `https://sdwebimage.github.io/index/index.json`

## Aktuální stav (DOKONČENO ✅)
**Online režim je plně funkční a připraven k produkčnímu použití.**

### Dokončené úkoly:
1. ✅ **Filtrace cest** - Implementována filtrace `data/documentation/` prefixu
2. ✅ **URL parsing** - Zjednodušeno a rozšířeno pro všechny use-cases 
3. ✅ **Index.json handling** - Automatické přesměrování na hlavní modul
4. ✅ **CLI interface** - Plně funkční online režim bez dodatečných přepínačů
5. ✅ **Testování** - Ověřeno na reálné dokumentaci (293 souborů, 598KB export)
6. ✅ **Error handling** - Graceful handling neúspěšných URL a dekódování

### Zbývající vylepšení (volitelné):
1. **Refaktorace** - Přesunout rekurzivní logiku z `main.swift` do `Export.swift`
2. **Cachování** - Přidat jednoduché cachování stažených souborů
3. **Metadata autodetekce** - Autodetekce hlavního indexu z kořenové URL
4. **Performance** - Paralelní stahování souborů
5. **Dokumentace** - Aktualizace README s online examples 