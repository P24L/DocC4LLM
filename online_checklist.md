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

## Další postup
1. **Filtrace cest**
   - Zpracovávat pouze cesty začínající na `data/documentation/` (prefix bude do budoucna parametrizovatelný).
   - Název knihovny (např. `atprotokit`) je součástí cesty, ale filtrujeme pouze podle obecného prefixu.
2. **Refaktorace**
   - Přesunout rekurzivní logiku prohledávání a exportu JSON souborů z `main.swift` do knihovny (např. do `DocCArchive/Export.swift`).
   - Zajistit lepší testovatelnost a opakované použití.
3. **Vstupní JSON soubor**
   - Aktuálně je jako vstupní bod potřeba zadat konkrétní indexový JSON (např. `https://atprotokit.cjrriley.com/data/documentation/atprotokit.json`).
   - Do budoucna vylepšit: umožnit zadat pouze kořenovou URL a automaticky najít hlavní index (např. podle konvence nebo metadata.json). Tento krok je náročnější a bude řešen později.
4. **Ošetřit chyby při stahování (timeout, 404, atd.)**
5. **(Volitelně) Přidat jednoduché cachování stažených souborů**
6. **Přidat CLI přepínač pro online režim (URL místo cesty)**
7. **Ověřit výstup a porovnat s lokální variantou**
8. **Zapsat poznatky a případné limity do README** 
9. **(Volitelné) Zvážit vytvoření pull requestu s úpravami zpět do původního DocCArchive repozitáře** 