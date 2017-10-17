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
| ...
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | NDRPDRDISC
| ... | NIC_Intel-X520-DA2 | ETH | L2XCFWD | BASE | L2XCBASE | MEMIF
| ... | KUBERNETES | 1VSWITCH | 1VNF | VPP_AGENT | SFC_CONTROLLER
| ...
| Suite Setup | Set up 3-node performance topology with DUT's NIC model
| ... | L2 | Intel-X520-DA2
| ...
| Test Setup | Run Keywords
| ... | Apply Kubernetes resource on all duts | ${nodes} | kafka.yaml
| ... | AND | Apply Kubernetes resource on all duts | ${nodes} | etcd.yaml
| ...
| Suite Teardown | Tear down 3-node performance topology
| ...
| Test Teardown | Run Keywords
| ... | Get Kubernetes logs on all DUTs | ${nodes} | AND
| ... | Describe Kubernetes resource on all DUTs | ${nodes} | AND
| ... | Delete Kubernetes resource on all duts | ${nodes}
| ...
| Documentation | *RFC2544: Pkt throughput L2XC test cases*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 for L2 cross connect.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with L2 cross-
| ... | connect. DUT1 and DUT2 tested with 2p10GE NIC X520 Niantic by Intel.
| ... | VNF Container is connected to VSWITCH container via Memif interface. All
| ... | containers is running same VPP version. Containers are deployed with
| ... | Kubernetes. Configuration is applied by vnf-agent.
| ... | *[Ver] TG verification:* TG finds and reports throughput NDR (Non Drop
| ... | Rate) with zero packet loss tolerance or throughput PDR (Partial Drop
| ... | Rate) with non-zero packet loss tolerance (LT) expressed in percentage
| ... | of packets transmitted. NDR and PDR are discovered for different
| ... | Ethernet L2 frame sizes using either binary search or linear search
| ... | algorithms with configured starting rate and final step that determines
| ... | throughput measurement resolution. Test packets are generated by TG on
| ... | links to DUTs. TG traffic profile contains two L3 flow-groups
| ... | (flow-group per direction, 253 flows per flow-group) with all packets
| ... | containing Ethernet header, IPv4 header with IP protocol=61 and static
| ... | payload. MAC addresses are matching MAC addresses of the TG node
| ... | interfaces.
| ... | *[Ref] Applicable standard specifications:* RFC2544.

*** Variables ***
| ${avg_imix_framesize}= | ${357.833}
# X520-DA2 bandwidth limit
| ${s_limit} | ${10000000000}
# Kubernetes profile
| ${kubernetes_profile} | eth-l2xcbase-eth-2memif-1vnf
# Traffic profile:
| ${traffic_profile} | trex-sl-3n-ethip4-ip4src254
# CPU settings
| ${system_cpus}= | ${1}
| ${vswitch_cpus}= | ${5}
| ${vnf_cpus}= | ${3}

*** Keywords ***
| Create Kubernetes VSWITCH startup config on all DUTs
| | [Documentation] | Create base startup configuration of VSWITCH in Kubernetes
| | ... | deploy to all DUTs.
| | ...
| | ... | *Arguments:*
| | ... | - ${framesize} - L2 framesize. Type: integer
| | ... | - ${wt} - Worker threads. Type: integer
| | ... | - ${rxq} - RX queues. Type: integer
| | ...
| | ... | *Example:*
| | ...
| | ... | \| Create Kubernetes VSWITCH startup config on all DUTs \| ${64} \
| | ... | \| ${1} \| ${1}
| | ...
| | [Arguments] | ${framesize} | ${wt} | ${rxq}
| | ${dut1_numa}= | Get interfaces numa node | ${dut1}
| | ... | ${dut1_if1} | ${dut1_if2}
| | ${dut2_numa}= | Get interfaces numa node | ${dut2}
| | ... | ${dut2_if1} | ${dut2_if2}
| | ${dut1_if1_pci}= | Get Interface PCI Addr | ${dut1} | ${dut1_if1}
| | ${dut1_if2_pci}= | Get Interface PCI Addr | ${dut1} | ${dut1_if2}
| | ${dut2_if1_pci}= | Get Interface PCI Addr | ${dut2} | ${dut2_if1}
| | ${dut2_if2_pci}= | Get Interface PCI Addr | ${dut2} | ${dut2_if2}
| | ${cpu_cnt}= | Evaluate | ${wt}+1
| | ${config}= | Run keyword | Create Kubernetes VSWITCH startup config
| | ... | node=${dut1} | cpu_cnt=${cpu_cnt} | cpu_node=${dut1_numa}
| | ... | cpu_skip=${system_cpus} | smt_used=${False}
| | ... | filename=/tmp/vswitch.conf | framesize=${framesize} | rxq=${rxq}
| | ... | if1=${dut1_if1_pci} | if2=${dut1_if2_pci}
| | ${config}= | Run keyword | Create Kubernetes VSWITCH startup config
| | ... | node=${dut2} | cpu_cnt=${cpu_cnt} | cpu_node=${dut2_numa}
| | ... | cpu_skip=${system_cpus} | smt_used=${False}
| | ... | filename=/tmp/vswitch.conf | framesize=${framesize} | rxq=${rxq}
| | ... | if1=${dut2_if1_pci} | if2=${dut2_if2_pci}

| Create Kubernetes VNF'${i}' startup config on all DUTs
| | [Documentation] | Create base startup configuration of VNF in Kubernetes
| | ... | deploy to all DUTs.
| | ...
| | ${i_int}= | Convert To Integer | ${i}
| | ${cpu_skip}= | Evaluate | ${vswitch_cpus}+${system_cpus}
| | ${dut1_numa}= | Get interfaces numa node | ${dut1}
| | ... | ${dut1_if1} | ${dut1_if2}
| | ${dut2_numa}= | Get interfaces numa node | ${dut2}
| | ... | ${dut2_if1} | ${dut2_if2}
| | ${config}= | Run keyword | Create Kubernetes VNF startup config
| | ... | node=${dut1} | cpu_cnt=${vnf_cpus} | cpu_node=${dut1_numa}
| | ... | cpu_skip=${cpu_skip} | smt_used=${False} | filename=/tmp/vnf${i}.conf
| | ... | i=${i_int}
| | ${config}= | Run keyword | Create Kubernetes VNF startup config
| | ... | node=${dut2} | cpu_cnt=${vnf_cpus} | cpu_node=${dut2_numa}
| | ... | cpu_skip=${cpu_skip} | smt_used=${False} | filename=/tmp/vnf${i}.conf
| | ... | i=${i_int}

| L2 Cross Connect Binary Search
| | [Arguments] | ${framesize} | ${min_rate} | ${wt} | ${rxq} | ${search_type}
| | Set Test Variable | ${framesize}
| | Set Test Variable | ${min_rate}
| | ${get_framesize}= | Set Variable If
| | ... | "${framesize}" == "IMIX_v4_1" | ${avg_imix_framesize} | ${framesize}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${get_framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_if1_name}= | Get interface name | ${dut1} | ${dut1_if1}
| | ${dut1_if2_name}= | Get interface name | ${dut1} | ${dut1_if2}
| | ${dut2_if1_name}= | Get interface name | ${dut2} | ${dut2_if1}
| | ${dut2_if2_name}= | Get interface name | ${dut2} | ${dut2_if2}
| | Create Kubernetes VSWITCH startup config on all DUTs | ${get_framesize}
| | ... | ${wt} | ${rxq}
| | Create Kubernetes VNF'1' startup config on all DUTs
| | Create Kubernetes CM from file on all DUTs | ${nodes} | name=vswitch-vpp-cfg
| | ... | key=vpp.conf | src_file=/tmp/vswitch.conf
| | Create Kubernetes CM from file on all DUTs | ${nodes} | name=vnf-vpp-cfg
| | ... | key=vpp.conf | src_file=/tmp/vnf1.conf
| | Apply Kubernetes resource on node | ${dut1}
| | ... | ${kubernetes_profile}.yaml | $$TEST_NAME$$=${TEST NAME}
| | ... | $$VSWITCH_IF1$$=${dut1_if1_name}
| | ... | $$VSWITCH_IF2$$=${dut1_if2_name}
| | Apply Kubernetes resource on node | ${dut2}
| | ... | ${kubernetes_profile}.yaml | $$TEST_NAME$$=${TEST NAME}
| | ... | $$VSWITCH_IF1$$=${dut2_if1_name}
| | ... | $$VSWITCH_IF2$$=${dut2_if2_name}
| | Wait for Kubernetes PODs on all DUTs | ${nodes}
| | Describe Kubernetes resource on all DUTs | ${nodes}
| | Run Keyword If | '${search_type}' == 'NDR'
| | ... | Find NDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ELSE IF | '${search_type}' == 'PDR'
| | ... | Find PDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

*** Test Cases ***
| tc01-64B-1t1c-eth-l2xcbase-eth-2memif-1vnf-kubernetes-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for 64 Byte frames using binary search start at 10GE\
| | ... | linerate, step 100kpps.
| | ...
| | [Tags] | 64B | 1T1C | STHREAD | NDRDISC
| | [Template] | L2 Cross Connect Binary Search
| | framesize=${64} | min_rate=${100000} | wt=1 | rxq=1 | search_type=NDR

| tc02-64B-1t1c-eth-l2xcbase-eth-2memif-1vnf-kubernetes-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Find PDR for 64 Byte frames using binary search start at 10GE\
| | ... | linerate, step 100kpps, LT=0.5%.
| | ...
| | [Tags] | 64B | 1T1C | STHREAD | PDRDISC
| | [Template] | L2 Cross Connect Binary Search
| | framesize=${64} | min_rate=${100000} | wt=1 | rxq=1 | search_type=PDR

| tc03-IMIX-1t1c-eth-l2xcbase-eth-2memif-1vnf-kubernetes-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for IMIX_v4_1 frames using binary search start at 10GE\
| | ... | linerate, step 10kpps.
| | ... | IMIX_v4_1 = (28x64B;16x570B;4x1518B)
| | ...
| | [Tags] | IMIX | 1T1C | STHREAD | NDRDISC
| | [Template] | L2 Cross Connect Binary Search
| | framesize=IMIX_v4_1 | min_rate=${10000} | wt=1 | rxq=1 | search_type=NDR

| tc04-IMIX-1t1c-eth-l2xcbase-eth-2memif-1vnf-kubernetes-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Find PDR for IMIX_v4_1 frames using binary search start at 10GE\
| | ... | linerate, step 10kpps, LT=0.5%.
| | ... | IMIX_v4_1 = (28x64B;16x570B;4x1518B)
| | ...
| | [Tags] | IMIX | 1T1C | STHREAD | PDRDISC
| | [Template] | L2 Cross Connect Binary Search
| | framesize=IMIX_v4_1 | min_rate=${10000} | wt=1 | rxq=1 | search_type=PDR

| tc05-1518B-1t1c-eth-l2xcbase-eth-2memif-1vnf-kubernetes-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for 1518 Byte frames using binary search start at 10GE\
| | ... | linerate, step 10kpps.
| | ...
| | [Tags] | 1518B | 1T1C | STHREAD | NDRDISC
| | [Template] | L2 Cross Connect Binary Search
| | framesize=${1518} | min_rate=${10000} | wt=1 | rxq=1 | search_type=NDR

| tc06-1518B-1t1c-eth-l2xcbase-eth-2memif-1vnf-kubernetes-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Find PDR for 1518 Byte frames using binary search start at 10GE\
| | ... | linerate, step 10kpps, LT=0.5%.
| | ...
| | [Tags] | 1518B | 1T1C | STHREAD | PDRDISC
| | [Template] | L2 Cross Connect Binary Search
| | framesize=${1518} | min_rate=${10000} | wt=1 | rxq=1 | search_type=PDR

| tc07-64B-2t2c-eth-l2xcbase-eth-2memif-1vnf-kubernetes-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 2 thread, 2 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for 64 Byte frames using binary search start at 10GE\
| | ... | linerate, step 100kpps.
| | ...
| | [Tags] | 64B | 2T2C | MTHREAD | NDRDISC
| | [Template] | L2 Cross Connect Binary Search
| | framesize=${64} | min_rate=${100000} | wt=2 | rxq=1 | search_type=NDR

| tc08-64B-2t2c-eth-l2xcbase-eth-2memif-1vnf-kubernetes-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 2 thread, 2 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Find PDR for 64 Byte frames using binary search start at 10GE\
| | ... | linerate, step 100kpps, LT=0.5%.
| | ...
| | [Tags] | 64B | 2T2C | MTHREAD | PDRDISC
| | [Template] | L2 Cross Connect Binary Search
| | framesize=${64} | min_rate=${100000} | wt=2 | rxq=1 | search_type=PDR

| tc09-IMIX-2t2c-eth-l2xcbase-eth-2memif-1vnf-kubernetes-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 2 thread, 2 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for IMIX_v4_1 frames using binary search start at 10GE\
| | ... | linerate, step 10kpps.
| | ... | IMIX_v4_1 = (28x64B;16x570B;4x1518B)
| | ...
| | [Tags] | IMIX | 2T2C | MTHREAD | NDRDISC
| | [Template] | L2 Cross Connect Binary Search
| | framesize=IMIX_v4_1 | min_rate=${10000} | wt=2 | rxq=1 | search_type=NDR

| tc10-IMIX-2t2c-eth-l2xcbase-eth-2memif-1vnf-kubernetes-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 2 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Find PDR for IMIX_v4_1 frames using binary search start at 10GE\
| | ... | linerate, step 10kpps, LT=0.5%.
| | ... | IMIX_v4_1 = (28x64B;16x570B;4x1518B)
| | ...
| | [Tags] | IMIX | 2T2C | MTHREAD | PDRDISC
| | [Template] | L2 Cross Connect Binary Search
| | framesize=IMIX_v4_1 | min_rate=${10000} | wt=2 | rxq=1 | search_type=PDR

| tc11-1518B-2t2c-eth-l2xcbase-eth-2memif-1vnf-kubernetes-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 2 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for 1518 Byte frames using binary search start at 10GE\
| | ... | linerate, step 10kpps.
| | ...
| | [Tags] | 1518B | 2T2C | MTHREAD | NDRDISC
| | [Template] | L2 Cross Connect Binary Search
| | framesize=${1518} | min_rate=${10000} | wt=2 | rxq=1 | search_type=NDR

| tc12-1518B-2t2c-eth-l2xcbase-eth-2memif-1vnf-kubernetes-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 2 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Find PDR for 1518 Byte frames using binary search start at 10GE\
| | ... | linerate, step 10kpps, LT=0.5%.
| | ...
| | [Tags] | 1518B | 2T2C | MTHREAD | PDRDISC
| | [Template] | L2 Cross Connect Binary Search
| | framesize=${1518} | min_rate=${10000} | wt=2 | rxq=1 | search_type=PDR
