snmpwalk -v 2c -c commavt-341-9 127.0.0.1 .1.3.6.1.4.1.2021.4.3.0 | awk -F'[.:: ]+' '{print $2 ": " $6, $7}' >> /root/avt341-9.log

snmpwalk -v 2c -c commavt-341-9 127.0.0.1 .1.3.6.1.4.1.2021.4.4.0 | awk -F'[.:: ]+' '{print $2 ": " $6, $7}' >> /root/avt341-9.log

snmpwalk -v 2c -c commavt-341-9 127.0.0.1 .1.3.6.1.4.1.2021.4 | awk '
/memTotalSwap.0/ {total=$4}
/memAvailSwap.0/ {avail=$4} 
END {print "Swap Used:", total-avail, "kB"}' >> /root/avt341-9.log


snmpwalk -v2c -c commavt-341-9 127.0.0.1 .1.3.6.1.4.1.2021.9.1 | \
awk -F' = ' '
BEGIN {
    printf "%-25s | %-30s | %-12s | %-12s | %-12s | %-12s | %-12s\n", "dskPath", "dskDevice", "dskTotal(kB)", "dskUsed(kB)", "dskAvail(kB)", "dskPercent(%)", "dskPercentNode(%)"
    printf "%-25s | %-30s | %-12s | %-12s | %-12s | %-12s | %-12s\n", "-------------------------", "------------------------------", "------------", "------------", "------------", "-------------", "-------------"
}
{
    gsub(/^.*::/, "", $1)
    gsub(/\.0$/, "", $1)
    
    split($1, parts, ".")
    param = parts[1]
    idx = parts[2]
    

    value = $2
    gsub(/^STRING: /, "", value)
    gsub(/^INTEGER: /, "", value)
    gsub(/^"/, "", value)
    gsub(/"$/, "", value)
    

    if (param == "dskPath") path[idx] = value
    if (param == "dskDevice") device[idx] = value
    if (param == "dskTotal") total[idx] = value
    if (param == "dskUsed") used[idx] = value
    if (param == "dskAvail") avail[idx] = value
    if (param == "dskPercent") percent[idx] = value
    if (param == "dskPercentNode") inode[idx] = value
}
END {

    for (i in path) {
        printf "%-25s | %-30s | %-12s | %-12s | %-12s | %-13s | %-12s\n", path[i], device[i], total[i], used[i], avail[i], percent[i], inode[i]
    }
}' >> /root/avt341-9.log