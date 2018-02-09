# Copyright (c) 2017 Cisco and/or its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

*** Settings ***
| Resource | resources/libraries/robot/performance/performance_setup.robot
| Resource | resources/libraries/robot/crypto/ipsec.robot
| ...
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | NDRPDRDISC
| ... | IP4FWD | IPSEC | IPSECSW | IPSECTUN | NIC_Intel-XL710 | BASE
| ...
| Suite Setup | Set up IPSec performance test suite | L3 | Intel-XL710
| ... | SW_cryptodev
| ...
| Suite Teardown | Tear down 3-node performance topology
| ...
| Test Setup | Set up performance test
| ...
| Test Teardown | Tear down performance discovery test | ${min_rate}pps
| ... | ${framesize} | ${traffic_profile}
| ...
| Documentation | *IPv4 IPsec tunnel mode performance test suite.*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 on TG-DUTn,
| ... | Eth-IPv4-IPSec on DUT1-DUT2
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with DPDK SW
| ... | crypto devices and multiple IPsec tunnels between them. DUTs get IPv4
| ... | traffic from TG, encrypt it and send to another DUT, where packets are
| ... | decrypted and sent back to TG.
| ... | *[Ver] TG verification:* TG finds and reports throughput NDR (Non Drop
| ... | Rate) with zero packet loss tolerance or throughput PDR (Partial Drop
| ... | Rate) with non-zero packet loss tolerance (LT) expressed in number
| ... | of packets transmitted. NDR is discovered for different
| ... | number of IPsec tunnels using binary search algorithms with configured
| ... | starting rate and final step that determines throughput measurement
| ... | resolution. Test packets are generated by TG on
| ... | links to DUTs. TG traffic profile contains two L3 flow-groups
| ... | (flow-group per direction, number of flows per flow-group equals to
| ... | number of IPSec tunnels) with all packets
| ... | containing Ethernet header, IPv4 header with IP protocol=61 and
| ... | static payload. MAC addresses are matching MAC addresses of the TG
| ... | node interfaces. Incrementing of IP.dst (IPv4 destination address) field
| ... | is applied to both streams.
| ... | *[Ref] Applicable standard specifications:* RFC4303 and RFC2544.

*** Variables ***
# XL710-DA2 bandwidth limit ~49Gbps/2=24.5Gbps
| ${s_limit} | ${24500000000}
# XL710-DA2 Mpps limit 37.5Mpps/2=18.75Mpps
| ${s_18.75Mpps} | ${18750000}
| ${tg_if1_ip4}= | 192.168.10.2
| ${dut1_if1_ip4}= | 192.168.10.1
| ${dut1_if2_ip4}= | 172.168.1.1
| ${dut2_if1_ip4}= | 172.168.1.2
| ${dut2_if2_ip4}= | 192.168.20.1
| ${tg_if2_ip4}= | 192.168.20.2
| ${raddr_ip4}= | 20.0.0.0
| ${laddr_ip4}= | 10.0.0.0
| ${addr_range}= | ${32}
| ${ipsec_overhead_gcm}= | ${54}
| ${n_tunnels}= | ${1}
# Traffic profile:
| ${traffic_profile} | trex-sl-3n-ethip4-ip4dst${n_tunnels}

*** Keywords ***
| Discover NDR or PDR for IPv4 routing with IPSec SW cryptodev
| | [Arguments] | ${wt} | ${rxq} | ${framesize} | ${min_rate} | ${search_type}
| | Set Test Variable | ${framesize}
| | Set Test Variable | ${min_rate}
| | ${get_framesize}= | Get Frame Size | ${framesize}
| | ${max_rate}= | Calculate pps | ${s_limit}
| | ... | ${get_framesize} + ${ipsec_overhead_gcm}
| | ${max_rate}= | Set Variable If
| | ... | ${max_rate} > ${s_18.75Mpps} | ${s_18.75Mpps} | ${max_rate}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${encr_alg}= | Crypto Alg AES CBC 128
| | ${auth_alg}= | Integ Alg SHA1 96
| | Given Add '${wt}' worker threads and '${rxq}' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Add DPDK SW cryptodev on DUTs in 3-node single-link circular topology
| | ... | aesni_mb | ${${wt}}
| | And Add DPDK dev default RXD to all DUTs | 2048
| | And Add DPDK dev default TXD to all DUTs | 2048
| | And Apply startup configuration on all VPP DUTs
| | And Generate keys for IPSec | ${encr_alg} | ${auth_alg}
| | And Initialize IPSec in 3-node circular topology
| | And VPP IPsec Create Tunnel Interfaces
| | ... | ${dut1} | ${dut2} | ${dut1_if2_ip4} | ${dut2_if1_ip4} | ${dut1_if2}
| | ... | ${dut2_if1} | ${n_tunnels} | ${encr_alg} | ${encr_key} | ${auth_alg}
| | ... | ${auth_key} | ${laddr_ip4} | ${raddr_ip4} | ${addr_range}
| | Then Run Keyword If | '${search_type}' == 'NDR'
| | ... | Find NDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ELSE IF | '${search_type}' == 'PDR'
| | ... | Find PDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

*** Test Cases ***
| tc01-64B-1t1c-ethip4ipsecbasetnlsw-ip4base-int-cbc-sha1-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUTs run 1 IPsec tunnel CBC-SHA1 in each direction, configured\
| | ... | with 1 thread, 1 phy core, 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for 64 Byte frames\
| | ... | using binary search start at 40GE linerate, step 50kpps.
| | ...
| | [Tags] | 64B | 1T1C | STHREAD | NDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv4 routing with IPSec SW cryptodev
| | wt=1 | rxq=1 | framesize=${64} | min_rate=${50000} | search_type=NDR

| tc02-64B-1t1c-ethip4ipsecbasetnlsw-ip4base-int-cbc-sha1-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUTs run 1 IPsec tunnel CBC-SHA1 in each direction, configured\
| | ... | with 1 thread, 1 phy core, 1 receive queue per NIC port.
| | ... | [Ver] Find PDR for 64 Byte frames using binary search start at 40GE\
| | ... | linerate, step 50kpps and loss tolerance of 0.5%.
| | ...
| | [Tags] | 64B | 1T1C | STHREAD | PDRDISC | SKIP_PATCH
| | ...
| | [Template] | Discover NDR or PDR for IPv4 routing with IPSec SW cryptodev
| | wt=1 | rxq=1 | framesize=${64} | min_rate=${50000} | search_type=PDR

| tc03-1518B-1t1c-ethip4ipsecbasetnlsw-ip4base-int-cbc-sha1-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUTs run 1 IPsec tunnel CBC-SHA1 in each direction, configured\
| | ... | with 1 thread, 1 phy core, 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for 1518 Byte frames\
| | ... | using binary search start at 40GE linerate, step 50kpps.
| | ...
| | [Tags] | 1518B | 1T1C | STHREAD | NDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv4 routing with IPSec SW cryptodev
| | wt=1 | rxq=1 | framesize=${1518} | min_rate=${50000} | search_type=NDR

| tc04-1518B-1t1c-ethip4ipsecbasetnlsw-ip4base-int-cbc-sha1-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUTs run 1 IPsec tunnel CBC-SHA1 in each direction, configured\
| | ... | with 1 thread, 1 phy core, 1 receive queue per NIC port.
| | ... | [Ver] Find PDR for 1518 Byte frames using binary search start at 40GE\
| | ... | linerate, step 50kpps and loss tolerance of 0.5%.
| | ...
| | [Tags] | 1518B | 1T1C | STHREAD | PDRDISC | SKIP_PATCH
| | ...
| | [Template] | Discover NDR or PDR for IPv4 routing with IPSec SW cryptodev
| | wt=1 | rxq=1 | framesize=${1518} | min_rate=${50000} | search_type=PDR

| tc05-IMIX-1t1c-ethip4ipsecbasetnlsw-ip4base-int-cbc-sha1-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUTs run 1 IPsec tunnel CBC-SHA1 in each direction, configured\
| | ... | with 1 thread, 1 phy core, 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for IMIX_v4_1 frames\
| | ... | using binary search start at 40GE linerate, step 50kpps.
| | ... | IMIX_v4_1 = (28x64B; 16x570B; 4x1518B)
| | ...
| | [Tags] | IMIX | 1T1C | STHREAD | NDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv4 routing with IPSec SW cryptodev
| | wt=1 | rxq=1 | framesize=IMIX_v4_1 | min_rate=${50000} | search_type=NDR

| tc06-IMIX-1t1c-ethip4ipsecbasetnlsw-ip4base-int-cbc-sha1-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUTs run 1 IPsec tunnel CBC-SHA1 in each direction, configured\
| | ... | with 1 thread, 1 phy core, 1 receive queue per NIC port.
| | ... | [Ver] Find PDR for IMIX_v4_1 frames using binary search start at 40GE\
| | ... | linerate, step 50kpps and loss tolerance of 0.5%.
| | ... | IMIX_v4_1 = (28x64B; 16x570B; 4x1518B)
| | ...
| | [Tags] | IMIX | 1T1C | STHREAD | PDRDISC | SKIP_PATCH
| | ...
| | [Template] | Discover NDR or PDR for IPv4 routing with IPSec SW cryptodev
| | wt=1 | rxq=1 | framesize=IMIX_v4_1 | min_rate=${50000} | search_type=PDR

| tc07-64B-2t2c-ethip4ipsecbasetnlsw-ip4base-int-cbc-sha1-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUTs run 1 IPsec tunnel CBC-SHA1 in each direction, configured\
| | ... | with 2 thread, 2 phy core, 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for 64 Byte frames\
| | ... | using binary search start at 40GE linerate, step 50kpps.
| | ...
| | [Tags] | 64B | 2T2C | MTHREAD | NDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv4 routing with IPSec SW cryptodev
| | wt=2 | rxq=1 | framesize=${64} | min_rate=${50000} | search_type=NDR

| tc08-64B-2t2c-ethip4ipsecbasetnlsw-ip4base-int-cbc-sha1-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUTs run 1 IPsec tunnel CBC-SHA1 in each direction, configured\
| | ... | with 2 thread, 2 phy core, 1 receive queue per NIC port.
| | ... | [Ver] Find PDR for 64 Byte frames using binary search start at 40GE\
| | ... | linerate, step 50kpps and loss tolerance of 0.5%.
| | ...
| | [Tags] | 64B | 2T2C | MTHREAD | PDRDISC | SKIP_PATCH
| | ...
| | [Template] | Discover NDR or PDR for IPv4 routing with IPSec SW cryptodev
| | wt=2 | rxq=1 | framesize=${64} | min_rate=${50000} | search_type=PDR
