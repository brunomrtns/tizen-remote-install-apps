# Repositório para NÃO sofrer: instalar apps (.wgt) em TV Samsung (Tizen) pela rede

Fluxo completo, mapeado a sangue, para instalar qualquer `.wgt` na TV Samsung
pelo PC via `sdb` (sem pendrive, sem USB, direto pela rede local).

---

## Ambiente mapeado (nossa rede)

| Item | Valor |
|---|---|
| PC | Windows 11, **192.168.1.16** (Ethernet cabo, rede `192.168.1.0/24`) |
| TV | Samsung **QN50Q60DAGXZD** (2024, Tizen), IP atual: **192.168.1.21** |
| Porta sdb da TV | `26101` (só aberta com Developer mode ligado) |
| Tizen Studio | `C:\tizen-studio` |
| CLI tizen | `C:\tizen-studio\tools\ide\bin\tizen.bat` |
| sdb | `C:\tizen-studio\tools\sdb.exe` |
| Perfil de assinatura | `tv` (arquivo: `C:\tizen-studio-data\profile\profiles.xml`) |
| Certificado Samsung | `C:\Users\Bruno\SamsungCertificate\tv\` (válido até **11/10/2027**) |
| DUID da TV no certificado | `XTCMR3DMMYTQQ` |
| Conta Samsung usada | brunomartinsss@gmail.com (tipo Individual) |

Apps já instalados assim na TV:
- **Moonlight** (`MoonLightS.MoonlightWasm`) — instalado em 11/10/2026
- **Saimo TV** (`SaimoTV001.SaimoTV`) — instalado em 06/11/2026, v2.6.7

---

## Pré-requisitos (já feitos — só refazer se algo quebrar)

> Passo a passo completo de como foi feito da primeira vez (Tizen Studio,
> login Samsung no Certificate Manager, dev mode na TV, DUID): **[docs/setup-do-zero.md](docs/setup-do-zero.md)**

1. **Developer mode na TV**: abrir **Apps**, digitar **12345** no controle,
   ligar *Developer mode* e colocar em **Server IP** o **IP atual do PC**.
   Depois **desligar a TV na tomada** e ligar de novo.
2. **Certificado Samsung** (Tizen Studio → Certificate Manager):
   - Tipo: **TV**, perfil chamado `tv`
   - Login com a conta Samsung
   - Adicionar o **DUID da TV** (`XTCMR3DMMYTQQ`) no perfil
   - Gera os arquivos em `C:\Users\Bruno\SamsungCertificate\tv\`
3. **profiles.xml** apontando para o certificado (perfil `tv` ativo em
   `C:\tizen-studio-data\profile\profiles.xml`).

> O certificado dura 1 ano. Depois de 11/10/2027 é preciso gerar de novo
> no Certificate Manager e adicionar o DUID da TV novamente.

---

## Fluxo para instalar um app novo

```powershell
# 1. Achar a TV na rede (se o IP mudou)
.\scripts\find-tv.ps1                # varre 192.168.1.0/24 atrás da porta 26101

# 2. Assinar o .wgt com o certificado da NOSSA TV (obrigatório)
.\scripts\sign-wgt.ps1 -Wgt C:\Users\Bruno\Downloads\App.wgt
# gera App-signed.wgt ao lado do original

# 3. Conectar na TV e instalar
.\scripts\install-wgt.ps1 -Wgt C:\Users\Bruno\Downloads\App-signed.wgt
```

Ou tudo em um comando só:

```powershell
.\scripts\install-wgt.ps1 -Wgt C:\Users\Bruno\Downloads\App.wgt -SignFirst
```

> Se o IP da TV mudou, passe `-TvIp <novo-ip>`.
> Depois de instalado, o app aparece em **Apps** na TV.

---

## Troubleshooting (tudo isso já aconteceu com a gente)

### `sdb connect` falha, mas a porta 26101 está aberta
Causa mais comum: o **Server IP na TV não é o IP atual do PC** (DHCP muda o IP).
- Na TV: Apps > `12345` > conferir *Server IP* = IP atual do PC
- Trocou o IP? **Reiniciar a TV na tomada** (segurar nada, só desligar e ligar).
  O power cycle foi o que resolveu nas duas vezes que travou.

### `install failed[118, -12] Check certificate error: Invalid certificate chain`
O `.wgt` veio assinado com certificado genérico. É obrigatório reassinar com o
perfil `tv` (`sign-wgt.ps1` faz isso).

### Certificate Manager com tela em branco / botão *Finish* cinza
Bug de DPI alto. Clique `< Previous` e `Next >` de novo, ou redimensione a
janela do assistente para forçar o redesenho.

### TV não aparece no `find-tv.ps1`
- Developer mode pode estar desligado (a TV fecha a 26101)
- TV e PC em redes diferentes / Wi-Fi com isolamento de cliente

### Firewall do Windows
Já existe regra inbound `sdb` liberada. Se sumir:
```powershell
netsh advfirewall firewall add rule name="sdb" dir=in action=allow program="C:\tizen-studio\tools\sdb.exe" enable=yes
```

---

## Como funciona (por baixo dos panos)

1. **Assinar**: `tizen package -t wgt -s tv -- <pasta extraída do wgt>`
   — assina com `author.p12` + `distributor.p12` do perfil `tv`. As senhas ficam
   nos arquivos `.pwd` (criptografados por máquina, gerados pelo Certificate Manager).
2. **Conectar**: `sdb connect <IP-DA-TV>:26101`
3. **Instalar**: `tizen install -n <arquivo-assinado>.wgt -s <IP>:26101 -t <MODELO>`

O `.wgt` é um zip comum (config.xml, index.html...). Por isso o script extrai,
assina e empacota de novo.

---

## Segurança

- **NUNCA** commitar `.p12`, `.pwd`, `.pri`, `.csr` (já estão no `.gitignore`).
  São as chaves que permitem instalar apps na TV.
- Não commitar `.wgt` assinado também (binário, e é pessoal para o DUID da TV).
