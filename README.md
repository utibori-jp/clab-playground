# clab-playground

[containerlab](https://containerlab.dev/) でネットワークを試すためのラボ集。

| ラボ | 内容 |
|---|---|
| `labs/ospf-triangle` | FRR ルータ 3 台を三角形につないだ OSPF ラボ |
| `labs/aws-3tier` | AWS の VPC（Public / Private / Trusted の 3 サブネット）を再現したラボ。`verify.sh` で疎通を一覧表示 |

## 動作環境

Windows では **WSL2 の Ubuntu に Docker と containerlab を直接インストール**し、VS Code の Remote - WSL でこのフォルダを開いて使う。

```
Windows ─ WSL2 Ubuntu（Docker Engine + containerlab）─ VS Code（Remote - WSL）
```

### Docker Desktop を使わない理由

- containerlab は、コンテナ同士を仮想ケーブル（veth）でつなぐとき、各コンテナのネットワーク空間をプロセス ID 経由で直接操作する。
- Docker Desktop のコンテナは別の環境（`docker-desktop` ディストリビューション）で動くため、Ubuntu からはそのプロセスが見えず、ラボの作成に失敗する。
- containerlab 公式も、Windows では WSL の Ubuntu に Docker を直接インストールする構成を推奨している。

Docker Desktop を入れている場合は、**Settings → Resources → WSL integration で Ubuntu をオフ**にしておく（Docker Desktop 自体は他の用途で使っていてもよい）。

## セットアップ

動作確認した環境：WSL 3.0.5 / カーネル 6.18 / Ubuntu 24.04 / containerlab 0.83

### 1. WSL を最新にする（PowerShell）

```powershell
wsl --install -d Ubuntu   # Ubuntu が未導入の場合
wsl --update
wsl --shutdown
```

古い WSL カーネル（5.15 系）は netem（遅延やパケットロスを作る機能）が入っていないため、`containerlab tools netem` が失敗する。`wsl --update` でカーネル 6.x 系にすれば使える。

### 2. systemd を有効にする（Ubuntu）

`/etc/wsl.conf` を次の内容にする。

```ini
[boot]
systemd=true

[automount]
options = "metadata"
```

`metadata` は、`/mnt/c` 配下のファイルに Linux の権限を持たせるための設定（ラボ内にマウントするスクリプトの実行権限などに使う）。

変更後は PowerShell で `wsl --shutdown` して Ubuntu を開き直す。

### 3. Docker と containerlab をインストールする（Ubuntu）

公式のセットアップスクリプトで、Docker Engine と containerlab をまとめて入れる。

```bash
curl -sL https://containerlab.dev/setup | sudo -E bash -s "all"
```

sudo なしで使えるように、グループに追加する。

```bash
sudo usermod -aG docker,clab_admins $USER
```

一度ログアウトして（`exit` して Ubuntu を開き直す）、`groups` に `docker` と `clab_admins` が出ていれば OK。

```bash
docker version
containerlab version
```

### 4. VS Code の拡張を入れる（Windows 側）

```powershell
code --install-extension ms-vscode-remote.remote-wsl
code --install-extension srl-labs.vscode-containerlab
```

containerlab 拡張は、WSL に接続したウィンドウでも有効にする（拡張画面で「Install in WSL: Ubuntu」）。

### 5. リポジトリを開く

Ubuntu で次を実行すると、VS Code が WSL 接続で開く。

```bash
cd /mnt/c/Users/<ユーザー名>/git
git clone https://github.com/utibori-jp/clab-playground.git
cd clab-playground
code .
```

## ラボの使い方

```bash
cd labs/aws-3tier
sudo containerlab deploy -t aws-3tier.clab.yml     # 起動
./verify.sh                                         # 疎通確認
sudo containerlab destroy -t aws-3tier.clab.yml     # 停止・削除
```

設定を変えて作り直すときは `deploy` に `--reconfigure` を付ける。使うイメージ（FRR、network-multitool、nginx、postgres）は初回の `deploy` 時に自動で取得される。

VS Code の containerlab 拡張からも、トポロジーの表示・起動・停止ができる。

### 遅延やパケットロスを入れる例

```bash
sudo containerlab tools netem set -n clab-aws-3tier-fw -i eth1 --delay 100ms --loss 5
sudo containerlab tools netem show -n clab-aws-3tier-fw
```

## 注意

- `clab-*/` には containerlab が作るランタイムファイル（CA の秘密鍵など）が入るため、`.gitignore` で除外している。
- WSL で使うファイルの改行コードが CRLF にならないよう、`.gitattributes` で LF に固定している。
- `labs/aws-3tier` の `POSTGRES_PASSWORD` はラボ用のダミー値。
