package main

import (
	"errors"
	"fmt"
	"net"
	"time"

	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"
	"github.com/google/gopacket/pcap"
)

type IPMac struct {
	ip     string
	mac    string
	device string
}

func getIpFromAddr(addr net.Addr) net.IP {
	var ip net.IP
	switch v := addr.(type) {
	case *net.IPNet:
		ip = v.IP
	case *net.IPAddr:
		ip = v.IP
	}
	if ip == nil || ip.IsLoopback() {
		return nil
	}
	ip = ip.To4()
	if ip == nil {
		return nil
	}
	return ip
}

func getIPS() ([]IPMac, error) {
	ifaces, ferror := net.Interfaces()
	if ferror != nil {
		return nil, ferror
	}
	// var ipmacs []IPMac = make([]IPMac, len(ifaces))
	ipmaces := make([]IPMac, len(ifaces))
	count := 0
	var item IPMac
	for _, iface := range ifaces {
		// filter down interface
		if iface.Flags&net.FlagUp == 0 {
			fmt.Printf("iface %s is down\n", iface.Name)
			continue
		}

		// filter lookback interface
		if iface.Flags&net.FlagLoopback != 0 {
			fmt.Printf("iface %s is lookback\n", iface.Name)
			continue
		}

		addrs, ferror := iface.Addrs()
		if ferror != nil {
			fmt.Printf("ifcae %s have no address\n", iface.Name)
			return nil, ferror
		}

		for _, addr := range addrs {
			ip := getIpFromAddr(addr)
			if ip == nil {
				fmt.Printf("ifcae %s have no ip\n", iface.Name)
				continue
			}
			fmt.Printf("iface %s is worked well, ip: %s, mac: %s\n",
				iface.Name,
				ip.To4(),
				iface.HardwareAddr.String())
			item.mac = iface.HardwareAddr.String()
			item.ip = ip.To4().String()
			item.device = iface.Name
			ipmaces[count] = item
			count++
		}
	}
	if len(ipmaces) > 0 {
		return ipmaces, nil
	}

	return nil, errors.New("the network already?")
}

var (
	snapshot_len int32         = 1024
	promiscuous  bool          = false
	timeout      time.Duration = 5 * time.Second
	sleepout     time.Duration = time.Second
)

func ARPListener(ipmac IPMac, stopNow *bool) {
	var cap_mac string
	var cap_ip string
	var device string
	var watch_ip string
	var watch_mac string

	device = ipmac.device
	watch_ip = ipmac.ip
	watch_mac = ipmac.mac

	handle, myerr := pcap.OpenLive(device, snapshot_len, promiscuous, timeout)
	if myerr != nil {
		fmt.Println(myerr)
		return
	}
	defer handle.Close()
	var filter string = "arp and src host " + watch_ip
	fmt.Println("filter...", filter)
	myerr = handle.SetBPFFilter(filter)
	if myerr != nil {
		fmt.Println(myerr)
		return
	}

	fmt.Println("here we go...")
	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
	for packet := range packetSource.Packets() {
		fmt.Printf("stopNow: %d, device %s\n", stopNow, device)
		if sleepout != time.Second {
			time.Sleep(sleepout)
			sleepout = time.Second
			*stopNow = true
			break
		}
		// Do something with a packet here.
		arpackaget := packet.Layer(layers.LayerTypeARP).(*layers.ARP)
		cap_ip = net.IP(arpackaget.SourceProtAddress).To4().String()
		cap_mac = net.HardwareAddr(arpackaget.SourceHwAddress).String()
		if cap_ip == watch_ip && watch_mac != cap_mac {
			fmt.Printf("IP Clonflict, betwen %s and %s from %s\n", watch_mac, cap_mac, watch_ip)
			sleepout = 3 * time.Second
		}
	}
	fmt.Printf("end loop...\n")
}

func main() {
	fmt.Println("Golang net package...")
	ipmacs, err := getIPS()
	if err != nil {
		fmt.Println(err)
	}

	var stopNow = false
	fmt.Println("google gopacket...")
	for _, ipmac := range ipmacs {
		if ipmac == (IPMac{}) {
			continue
		}
		go ARPListener(ipmac, &stopNow)
	}
	for {
		fmt.Println("start main loop....")
		if stopNow {
			ipmacs, err = getIPS()
			if err != nil {
				fmt.Println(err)
				break
			}
			for _, ipmac := range ipmacs {
				if ipmac == (IPMac{}) {
					continue
				}
				go ARPListener(ipmac, &stopNow)
			}
			stopNow = false
		}
		time.Sleep(10 * time.Second)
	}
}
