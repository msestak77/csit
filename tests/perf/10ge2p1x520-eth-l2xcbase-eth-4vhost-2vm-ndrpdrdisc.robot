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
| Resource | resources/libraries/robot/performance.robot
| Library | resources.libraries.python.NodePath
| ...
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | NDRPDRDISC
| ... | NIC_Intel-X520-DA2 | ETH | L2XCFWD | BASE | VHOST | VM
| ...
| Suite Setup | Set up 3-node performance topology with DUT's NIC model
| ... | L2 | Intel-X520-DA2
| Suite Teardown | Tear down 3-node performance topology
| ...
| Test Setup | Set up performance test
| Test Teardown | Tear down performance test with vhost and VM with dpdk-testpmd
| ... | ${min_rate}pps | ${framesize}
| ... | ${traffic_profile}
| ... | dut1_node=${dut1} | dut1_vm_refs=${dut1_vm_refs}
| ... | dut2_node=${dut2} | dut2_vm_refs=${dut2_vm_refs}
| ...
| Documentation | *RFC2544: Pkt throughput L2XC test cases with vhost*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 for L2 cross connect.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with L2 cross-
| ... | connects. Qemu Guests are connected to VPP via vhost-user interfaces.
| ... | Guests are running DPDK testpmd interconnecting vhost-user interfaces
| ... | using 5 cores pinned to cpus 6-10 and 11-15 and 2048M memory. Testpmd is
| ... | using socket-mem=1024M (512x2M hugepages), 5 cores (1 main core and 4
| ... | cores dedicated for io), forwarding mode is set to io, rxd/txd=256,
| ... | burst=64. DUT1, DUT2 are tested with 2p10GE NIC X520 Niantic by Intel.
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
# X520-DA2 bandwidth limit
| ${s_limit} | ${10000000000}
#CPU settings
| ${system_cpus}= | ${1}
| ${vpp_cpus}= | ${5}
| ${vm_cpus}= | ${5}
# Traffic profile:
| ${traffic_profile} | trex-sl-3n-ethip4-ip4src254

*** Test Cases ***
| tc01-64B-1t1c-eth-l2xcbase-eth-4vhost-2vm-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Find NDR for 64 Byte frames \
| | ... | using binary search start at 10GE linerate, step 10kpps.
| | [Tags] | 64B | 1T1C | STHREAD | NDRDISC
| | ${framesize}= | Set Variable | ${64}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '1' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find NDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}

| tc02-64B-1t1c-eth-l2xcbase-eth-4vhost-2vm-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Find PDR for 64 Byte frames \
| | ... | using binary search start at 10GE linerate, step 10kpps, LT=0.5%.
| | [Tags] | 64B | 1T1C | STHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${64}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '1' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find PDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

| tc03-1518B-1t1c-eth-l2xcbase-eth-4vhost-2vm-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Find NDR for 1518 Byte frames \
| | ... | using binary search start at 10GE linerate, step 10kpps.
| | [Tags] | 1518B | 1T1C | STHREAD | NDRDISC
| | ${framesize}= | Set Variable | ${1518}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '1' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find NDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}

| tc04-1518B-1t1c-eth-l2xcbase-eth-4vhost-2vm-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Find PDR for 1518 Byte frames \
| | ... | using binary search start at 10GE linerate, step 10kpps, LT=0.5%.
| | [Tags] | 1518B | 1T1C | STHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${1518}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '1' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find PDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

| tc05-IMIX-1t1c-eth-l2xcbase-eth-4vhost-2vm-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Find NDR for IMIX_v4_1 frame \
| | ... | size using binary search start at 10GE linerate, step 10kpps.
| | ... | IMIX_v4_1 = (28x64B;16x570B;4x1518B)
| | [Tags] | IMIX | 1T1C | STHREAD | NDRDISC
| | ${framesize}= | Set Variable | IMIX_v4_1
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '1' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find NDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}

| tc06-IMIX-1t1c-eth-l2xcbase-eth-4vhost-2vm-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Find PDR for IMIX_v4_1 frame \
| | ... | size using binary search start at 10GE linerate, step 10kpps, LT=0.5%.
| | ... | IMIX_v4_1 = (28x64B;16x570B;4x1518B)
| | [Tags] | IMIX | 1T1C | STHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | IMIX_v4_1
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '1' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find PDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

| tc07-64B-2t2c-eth-l2xcbase-eth-4vhost-2vm-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Find NDR for 64 Byte frames \
| | ... | using binary search start at 10GE linerate, step 10kpps.
| | [Tags] | 64B | 2T2C | MTHREAD | NDRDISC
| | ${framesize}= | Set Variable | ${64}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '2' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find NDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}

| tc08-64B-2t2c-eth-l2xcbase-eth-4vhost-2vm-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Find PDR for 64 Byte frames \
| | ... | using binary search start at 10GE linerate, step 10kpps, LT=0.5%.
| | [Tags] | 64B | 2T2C | MTHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${64}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '2' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find PDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

| tc09-1518B-2t2c-eth-l2xcbase-eth-4vhost-2vm-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Find NDR for 1518 Byte frames \
| | ... | using binary search start at 10GE linerate, step 10kpps.
| | [Tags] | 1518B | 2T2C | MTHREAD | NDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${1518}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '2' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find NDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}

| tc10-1518B-2t2c-eth-l2xcbase-eth-4vhost-2vm-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Find PDR for 1518 Byte frames \
| | ... | using binary search start at 10GE linerate, step 10kpps, LT=0.5%.
| | [Tags] | 1518B | 2T2C | MTHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${1518}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '2' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find PDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

| tc11-IMIX-2t2c-eth-l2xcbase-eth-4vhost-2vm-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Find NDR for IMIX_v4_1 frame \
| | ... | size using binary search start at 10GE linerate, step 10kpps.
| | ... | IMIX_v4_1 = (28x64B;16x570B;4x1518B)
| | [Tags] | IMIX | 2T2C | MTHREAD | NDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | IMIX_v4_1
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '2' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find NDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}

| tc12-IMIX-2t2c-eth-l2xcbase-eth-4vhost-2vm-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Find PDR for IMIX_v4_1 frame \
| | ... | size using binary search start at 10GE linerate, step 10kpps, LT=0.5%.
| | ... | IMIX_v4_1 = (28x64B;16x570B;4x1518B)
| | [Tags] | IMIX | 2T2C | MTHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | IMIX_v4_1
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '2' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find PDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

| tc13-64B-4t4c-eth-l2xcbase-eth-4vhost-2vm-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Find NDR for 64 Byte frames \
| | ... | using binary search start at 10GE linerate, step 10kpps.
| | [Tags] | 64B | 4T4C | MTHREAD | NDRDISC
| | ${framesize}= | Set Variable | ${64}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '4' worker threads and '2' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find NDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}

| tc14-64B-4t4c-eth-l2xcbase-eth-4vhost-2vm-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Find PDR for 64 Byte frames \
| | ... | using binary search start at 10GE linerate, step 10kpps, LT=0.5%.
| | [Tags] | 64B | 4T4C | MTHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${64}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '4' worker threads and '2' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find PDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

| tc15-1518B-4t4c-eth-l2xcbase-eth-4vhost-2vm-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Find NDR for 1518 Byte frames \
| | ... | using binary search start at 10GE linerate, step 10kpps.
| | [Tags] | 1518B | 4T4C | MTHREAD | NDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${1518}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '4' worker threads and '2' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find NDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}

| tc16-1518B-4t4c-eth-l2xcbase-eth-4vhost-2vm-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Find PDR for 1518 Byte frames \
| | ... | using binary search start at 10GE linerate, step 10kpps, LT=0.5%.
| | [Tags] | 1518B | 4T4C | MTHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${1518}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '4' worker threads and '2' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find PDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

| tc17-IMIX-4t4c-eth-l2xcbase-eth-4vhost-2vm-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Find NDR for IMIX_v4_1 frame \
| | ... | size using binary search start at 10GE linerate, step 10kpps.
| | ... | IMIX_v4_1 = (28x64B;16x570B;4x1518B)
| | [Tags] | IMIX | 4T4C | MTHREAD | NDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | IMIX_v4_1
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '4' worker threads and '2' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find NDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}

| tc18-IMIX-4t4c-eth-l2xcbase-eth-4vhost-2vm-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC switching config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Find PDR for IMIX_v4_1 frame \
| | ... | size using binary search start at 10GE linerate, step 10kpps, LT=0.5%.
| | ... | IMIX_v4_1 = (28x64B;16x570B;4x1518B)
| | [Tags] | IMIX | 4T4C | MTHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | IMIX_v4_1
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | Given Add '4' worker threads and '2' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 xconnect with Vhost-User for '2' in 3-node circular topology
| | And Configure '2' guest VMs with dpdk-testpmd connected via vhost-user in 3-node circular topology
| | Then Find PDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}
