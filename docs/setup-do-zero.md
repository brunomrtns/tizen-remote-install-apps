# Setup do ZERO — tudo que foi feito na primeira vez (11/10/2026)

> Fonte: log completo da sessão de instalação do Moonlight (11/10/2026) + estado
> atual da máquina. Se um dia precisar refazer (PC novo, Windows reinstallado,
> TV nova, certificado vencido), é seguir isso aqui na ordem.

## O que precisou na primeira vez (resumo)

| Coisa | Onde | Quando refazer |
|---|---|---|
| Tizen Studio instalado | PC (`C:\tizen-studio`) | PC novo / format |
| Certificado Samsung + login Samsung | PC (Certificate Manager) | **Vence 11/10/2027** ou TV nova |
| Developer mode + Server IP | TV | Só se desligar sozinho / trocar de IP o PC |
| Porta 26101 liberada no firewall do roteador | rede | Normalmente nada |

## 1. Tizen Studio (no PC)

- Baixar em https://developer.samsung.com/tizen (Tizen Studio **com TV extensions**).
- Instalar em `C:\tizen-studio` (padrão que usamos). Ele instala junto:
  - `tools\sdb.exe` — o "adb do Tizen" (conecta na TV)
  - `tools\ide\bin\tizen.bat` — CLI de empacotar/assinar/instalar
  - **Certificate Manager** — gera o certificado Samsung
- Dados do SDK ficam em `C:\tizen-studio-data` (é lá que fica o `profiles.xml`).
- O Windows Firewall cria regra "sdb" na instalação (inbound allow). Se não criar,
  ver comando no README principal.

## 2. Modo desenvolvedor (NA TV — sem conta, sem login)

1. TV na mesma rede do PC (a nossa: `192.168.1.0/24`).
2. Botão **Apps** no controle → com a lista de apps aberta, digitar **12345**.
3. Abrir painel de desenvolvedor:
   - **Developer mode** → **On**
   - **Server IP** → o **IP atual do PC** (hoje: `192.168.1.16`)
4. **Reiniciar a TV na tomada** (desligar/ligar). SEM isso o `sdb connect` falha —
   foi o que travou a gente na primeira vez (porta abria, handshake recusava).
5. Pronto — a porta **26101** da TV passa a aceitar `sdb connect`.

> Não tem login Samsung na TV. O login é no PC, no Certificate Manager (passo 3).

## 3. Certificado Samsung (no PC — AQUI é o login com conta)

Feito pelo **Certificate Manager** do Tizen Studio (Tools > Certificate Manager):

1. **+** para criar perfil → tipo **TV** (não "Wearable"/"Mobile").
2. Nome do perfil: **`tv`** (é o `-s tv` dos comandos).
3. Author certificate: criar novo → pede **login com conta Samsung**
   (a nossa: brunomartinsss@gmail.com, tipo **Individual**).
4. Distributor certificate: tipo **TV** → aqui entra o **DUID da TV**
   (`XTCMR3DMMYTQQ`). O DUID aparece no Device Manager do Tizen Studio
   (conecta a TV por IP lá) ou no painel 12345 da TV.
5. Finish → gera os arquivos em `C:\Users\Bruno\SamsungCertificate\tv\`:
   `author.p12`, `distributor.p12` (+ `.pwd` com as senhas criptografadas)
   e o `profiles.xml` em `C:\tizen-studio-data\profile\`.

### Perrengue conhecido: tela em branco / botão Finish cinza
Bug de DPI alto do Certificate Manager. Resolveu:
- clicar **< Previous** e **Next >** de novo; ou
- arrastar/redimensionar a janela do assistente (força redesenho).

### Validade
O certificado dura **1 ano** (vence **11/10/2027**). Depois disso, instalar app
novo dá erro de certificado — é só abrir o Certificate Manager, renovar e
confirmar o DUID de novo. Apps já instalados continuam funcionando.

## 4. Testar a conexão (PC → TV)

```powershell
& C:\tizen-studio\tools\sdb.exe connect 192.168.1.21:26101
& C:\tizen-studio\tools\sdb.exe devices   # deve listar QN50Q60DAGXZD
```

## 5. Instalar um app (fluxo de sempre)

```powershell
.\scripts\sign-wgt.ps1 -Wgt app.wgt                    # assina com perfil tv
.\scripts\install-wgt.ps1 -Wgt app-signed.wgt          # conecta e instala
```

---

## Histórico do que já tentamos (pra não repetir erro)

- **Docker/WSL** (imagem `moonlight-chrome-tizen`): funciona pra conectar, mas o
  wgt vem assinado com certificado genérico → TV recusa com
  `install failed[118, -12] Invalid certificate chain`. Assinatura tem que ser
  com o certificado da NOSSA TV, do Windows mesmo.
- **sdb connect falha com porta aberta**: sempre foi Server IP errado na TV ou
  falta de power cycle (ocorreu 2x — 11/10 e 06/11).
- **IPs mudam por DHCP**: PC já foi `192.168.1.180`, hoje é `192.168.1.16`.
  TV já foi `192.168.1.26`, hoje `192.168.1.21`. Se mudar: atualizar Server IP
  na TV (e reiniciar na tomada) e achar a TV de novo com `find-tv.ps1`.
