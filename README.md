# marzban-backup
AC-LOVER backup importer


<p align="center">
 <a href="./README.md">
 English
 </a>
 /
 <a href="./README-fa.md">
 فارسی
 </a>
</p>

# Marzban Backup Script

This repository provides an automated solution for managing Marzban backups and restoring them efficiently.

---

## How to Work

### Step 1: Upload Backup
Upload your backup file to the `/root` directory on your server.

### Step 2: Install Marzban
Install [Marzban](https://github.com/Gozargah/Marzban) on your server.

### Step 3: Run the Script
Execute the following script to start the restoration process:
```bash
sudo bash <(curl -Ls https://github.com/ppouria/marzban-backup/raw/main/backup.sh)
```

---

## Possible Problems

If you have entered everything correctly, the backup file should be processed and restored successfully.  
If there are any issues, you can raise them in the [issues](https://github.com/ppouria/marzban-backup/issues) section.

---

## Help Us

I used a translator, so if there are any grammatical mistakes, please help me improve the documentation.  
Currently, this script is only tested on Ubuntu. Developers can contribute to make it compatible with other operating systems.

---

## Donations

If you like Marzhelp and would like to support further development, consider making a donation:

- **Tether (TRX/USDT):** `TGftLESDAeRncE7yMAHrTUCsixuUwPc6qp`
- **Bitcoin:** `bc1qnmuuxraew34g806ewkepxrhgln4ult6z5vkj9l`
- **ETH, BNB, MATIC network (ERC20, BEP20):** `0x413eb47C430a3eb0E4262f267C1AE020E0C7F84D`
- **TON:** `UQDNpA3SlFMorlrCJJcqQjix93ijJfhAwIxnbTwZTLiHZ0Xa`

---

## License

Made in [Unknown!] and Published under [AGPL-3.0](./LICENSE).

