# Case: Saimo TV — app não dava play (browser da TV funcionava)

## Sintoma
- App instalado (v2.6.7): clicar em filme/canal não reproduzia.
- Mesmo conteúdo em `saimo-tv.pages.dev` no **browser da TV**: funcionava.

## Arquitetura do app (mapeada em 06/11/2026)
- O app tem **dois players** e escolhe pela plataforma:
  - Tizen com `webapis.avplay` → **AVPlay nativo** (`class ql`, "player de hardware Tizen AVPlay")
  - Browser → **MSE/HLS.js** (`class Pl`, `<video>` + hls.js só pra `.m3u8`/`.txt`; mp4 vai direto em `video.src`)
  - webOS → player próprio (irrelevante aqui)
- Conteúdo vem de Cloudflare Pages:
  - Catálogo filmes: `https://filmes-saimo.pages.dev/{indice,fichas,destaques,filmes-A..Z,series-*}.txt`
  - Canais: `https://canais-saimo.pages.dev/{catalogo,guia,radios}.txt`
- Cada título tem lista de fontes (`activeSources`); a 1ª costuma ser **mp4 direto em HTTP porta 80**
  (servidores Xtream tipo `http://host:80/movie/USER/PASS/ID.mp4`), com fallback
  `https://saimo-tv.pages.dev/api/stream?tipo=movie&id=X&versao=dub`.
- Testado do PC: **as URLs estão vivas** — 302 → proxy Cloudflare Worker → `video/mp4` com Range (206).
  Ou seja, o problema NÃO é o servidor de stream.
- O app tem `failoverNextSource()` (troca de fonte) e o OSD mostra "Fonte N de M".

## Diagnóstico
O player **AVPlay** falha nesses streams (prepare/open), enquanto o mesmo stream no
`<video>` do browser da TV funciona. Como o app já embute o hls.js e o player browser
(`Pl`), a correção é **forçar o app a usar o player do browser** também no Tizen.

## Patch aplicado (em `saimo-tv.js`, build 2.6.7)
Arquivo minificado; substituição única (1 ocorrência):

```js
// antes
return De.isTizen&&((s=window.webapis)!=null&&s.avplay)?
// depois
return !1&&((s=window.webapis)!=null&&s.avplay)?
```

Com `!1` (false) o ternário cai no player MSE/HLS (`new Pl(e,t)`), o mesmo do browser.
Os nomes `De`, `s`, `Pl` são do build 2.6.7 — em versão nova do app, procurar o padrão
`isTizen&&...avplay` de novo (ver `scripts/patch-saimo.ps1`).

## Como reproduzir o fix
```powershell
# extrai o wgt original, aplica o patch, assina com perfil tv e instala
.\scripts\patch-saimo.ps1 -Wgt C:\Users\Bruno\Downloads\SaimoTV-Samsung.wgt
.\scripts\install-wgt.ps1 -Wgt C:\Users\Bruno\Downloads\SaimoTV-Samsung-patched.wgt
```

## Notas
- Se uma versão nova do SaimoTV sair, o patch precisa ser reaplicado (o arquivo JS muda).
- Cuidado ao gravar o JS de volta: usar `[IO.File]::WriteAllText` (UTF-8 **sem BOM**);
  `Set-Content -Encoding UTF8` no PS 5.1 adiciona BOM.
