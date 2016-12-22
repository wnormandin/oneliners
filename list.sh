# Check for the to 10 IPs by mod_security hit, log geoip data and the top 3 URIs hit
dt () { read tm; result=$(date +%s -d "$tm"); echo $result;}; start=$(echo "1 day ago" | dt); while IFS= read line; do time_stamp=$(echo "$line" | cut -d[ -f2 | cut -d] -f1 | dt ); if [ $time_stamp -gt $start ]; then echo $line; fi; done < <(grep "ModSecurity: Access denied" /usr/local/apache/logs/error_log) | tr -d '[' | awk -vFS="]" '$9 ~ /uri/{col=9}; $11 ~ /uri/{col=11};{print $3,$col}' | awk '{ printf "%s %s\n", $2, $4 }' | read data; top_10_ips=$(echo "$data" | cut -d' ' -f1 | sort | uniq -c | sort -n | tail -10); while IFS= read val; do ip=$(echo $val | cut -d' ' -f2 | tr -d ' '); ret_str="\n<<$val>>\n$(geoiplookup $ip)\nTop 3 URIs:\n$( grep "$ip" <<< "$data" | cut -d' ' -f2 | sort | uniq -c | sort -n | tail -3)"; echo -e "$ret_str"; done < <(echo "$top_10_ips" | tr -s " ") >> mod_sec_ip_hotlist.log &

# Find files for all users under a certain reseller (cpanel/WHM servers only) where
# modified and changed times are not identical
get_users () { echo $(grep "$1" /etc/trueuserowners | cut -d: -f1); }; check_modified () { if [ $# != 1 ]; then echo "A reseller/owner is required, usage: check_modified <username>"; exit 1; fi; reseller=$1; echo "Report for owner <<$reseller>>"; usr_count=$(get_users $reseller | wc -l); echo "Users: $usr_count"; if [ $usr_count -lt 1 ]; then echo "No users"; exit 1; fi; while IFS= read -r user; do homedir=$(getent passwd "$user" | cut -d: -f6); out_list=$(find "$homedir" -type f -name *.php -o -name *.js -exec stat -c %n#%Y#%Z {} \; | awk -F# '{if ($2 != $3) print $1}'); out_str="\n<<User $user>>\nHomeDir: $homedir\nFiles with modified/changed date discrepancies:\n$out_list"; echo -e "$out_str"; done < <(get_users "$reseller"); }; check_modified <reseller/owner>
