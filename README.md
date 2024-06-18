### Start
```bash
sudo docker run --rm \
  --privileged \
  --network host \
  -e WIFI_INTERFACE=wlxe84e0619ceab \
  -e OUTGOING_INTERFACE=ens33 \
  --name wifiap \
  developercyrus/wifiap
```

### End
```bash
sudo docker stop wifiap

sudo iptables -t nat -D POSTROUTING -o $OUTGOING_INTERFACE -j MASQUERADE
sudo iptables- D FORWARD -i wlxe84e0619ceab -o ens33 -j ACCEPT
sudo iptables -D FORWARD -i ens33 -o wlxe84e0619ceab -m state --state RELATED,ESTABLISHED -j ACCEPT
```
