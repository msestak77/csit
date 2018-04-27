# Copyright (c) 2018 Cisco and/or its affiliates.
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
| Documentation | *RFC2544: Pkt throughput L2BD test cases with vhost*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 for L2 switching of IPv4.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with L2 bridge-
| ... | domain and MAC learning enabled. Qemu Guest is connected to VPP via
| ... | vhost-user interfaces. Guest is running DPDK testpmd interconnecting
| ... | vhost-user interfaces using 5 cores pinned to cpus 5-9 and 2048M
| ... | memory. Testpmd is using socket-mem=1024M (512x2M hugepages), 5 cores
| ... | (1 main core and 4 cores dedicated for io), forwarding mode is set to
| ... | io, rxd/txd=1024, burst=64. DUT1, DUT2 are tested with 2p10GE NIC X520
| ... | Niantic by Intel.
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
| ...
| Resource | resources/libraries/robot/performance/performance_setup.robot
| Library | resources.libraries.python.QemuUtils
| ...
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | NDRPDR
| ... | NIC_Intel-X520-DA2 | ETH | L2BDMACLRN | BASE | VHOST | VM | VHOST_1024
| ...
| Suite Setup | Set up 3-node performance topology with DUT's NIC model
| ... | L2 | Intel-X520-DA2
| Suite Teardown | Tear down 3-node performance topology
| ...
| Test Setup | Set up performance test
| Test Teardown | Tear down performance test with vhost and VM with dpdk-testpmd
| ... | ${10000}pps | ${64} | ${traffic_profile}
| ... | dut1_node=${dut1} | dut1_vm_refs=${dut1_vm_refs}
| ... | dut2_node=${dut2} | dut2_vm_refs=${dut2_vm_refs}
| ...
| Test Template | Find NDRPDR for eth-l2bdbasemaclrn-eth-2vhostvr1024-1vm

*** Variables ***
| ${perf_qemu_qsz}= | 1024
| ${min_rate}= | ${20000}
# X520-DA2 bandwidth limit
| ${s_limit} | ${10000000000}
# Socket names
| ${bd_id1}= | 1
| ${bd_id2}= | 2
| ${sock1}= | /tmp/sock-1-${bd_id1}
| ${sock2}= | /tmp/sock-1-${bd_id2}
# Traffic profile:
| ${traffic_profile} | trex-sl-3n-ethip4-ip4src254

*** Keywords ***
| Find NDRPDR for eth-l2bdbasemaclrn-eth-2vhostvr1024-1vm
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD switching config with ${wt} thread, ${wt} phy\
| | ... | core, ${rxq} receive queue per NIC port.
| | ... | [Ver] Find NDR for ${framesize} frames \
| | ... | using binary search start at 10GE linerate.
| | ...
| | [Arguments] | ${framesize} | ${wt} | ${rxq}
| | ...
| | # Test Variables required for test and test teardown
| | Set Test Variable | ${framesize}
| | ${get_framesize}= | Get Frame Size | ${framesize}
| | ${max_unidirectional_rate}= | Calculate pps | ${s_limit} | ${get_framesize}
| | ${max_rate}= | Evaluate | 2*${max_unidirectional_rate}
| | ${dut1_vm_refs}= | Create Dictionary
| | ${dut2_vm_refs}= | Create Dictionary
| | Set Test Variable | ${dut1_vm_refs}
| | Set Test Variable | ${dut2_vm_refs}
| | ${jumbo_frames}= | Set Variable If | ${get_framesize} < ${1522}
| | ... | ${False} | ${True}
| | ...
| | Given Add '${wt}' worker threads and '${rxq}' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Run Keyword If | ${get_framesize} < ${1522}
| | ... | Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 bridge domains with Vhost-User in 3-node circular topology
| | ... | ${bd_id1} | ${bd_id2} | ${sock1} | ${sock2}
| | ${vm1}= | And Configure guest VM with dpdk-testpmd connected via vhost-user
| | ... | ${dut1} | ${sock1} | ${sock2} | DUT1_VM1
| | ... | jumbo_frames=${jumbo_frames}
| | Set To Dictionary | ${dut1_vm_refs} | DUT1_VM1 | ${vm1}
| | ${vm2}= | And Configure guest VM with dpdk-testpmd connected via vhost-user
| | ... | ${dut2} | ${sock1} | ${sock2} | DUT2_VM1
| | ... | jumbo_frames=${jumbo_frames}
| | Set To Dictionary | ${dut2_vm_refs} | DUT2_VM1 | ${vm2}
| | Then Find NDR and PDR intervals using optimized search
| | ... | ${framesize} | ${traffic_profile} | ${min_rate} | ${max_rate}

*** Test Cases ***
| tc01-64B-1t1c-eth-l2bdbasemaclrn-eth-2vhostvr1024-1vm-ndrpdr
| | [Tags] | 64B | 1T1C | STHREAD
| | ...
| | framesize=${64} | wt=1 | rxq=1

| tc02-1518B-1t1c-eth-l2bdbasemaclrn-eth-2vhostvr1024-1vm-ndrpdr
| | [Tags] | 1518B | 1T1C | STHREAD
| | ...
| | framesize=${1518} | wt=1 | rxq=1

| tc03-9000B-1t1c-eth-l2bdbasemaclrn-eth-2vhostvr1024-1vm-ndrpdr
| | [Tags] | 9000B | 1T1C | STHREAD
| | ...
| | framesize=${9000} | wt=1 | rxq=1

| tc04-IMIX-1t1c-eth-l2bdbasemaclrn-eth-2vhostvr1024-1vm-ndrpdr
| | [Tags] | IMIX | 1T1C | STHREAD
| | ...
| | framesize=IMIX_v4_1 | wt=1 | rxq=1

| tc05-64B-2t2c-eth-l2bdbasemaclrn-eth-2vhostvr1024-1vm-ndrpdr
| | [Tags] | 64B | 2T2C | MTHREAD
| | ...
| | framesize=${64} | wt=2 | rxq=1

| tc06-1518B-2t2c-eth-l2bdbasemaclrn-eth-2vhostvr1024-1vm-ndrpdr
| | [Tags] | 1518B | 2T2C | MTHREAD
| | ...
| | framesize=${1518} | wt=2 | rxq=1

| tc07-9000B-2t2c-eth-l2bdbasemaclrn-eth-2vhostvr1024-1vm-ndrpdr
| | [Tags] | 9000B | 2T2C | MTHREAD
| | ...
| | framesize=${9000} | wt=2 | rxq=1

| tc08-IMIX-2t2c-eth-l2bdbasemaclrn-eth-2vhostvr1024-1vm-ndrpdr
| | [Tags] | IMIX | 2T2C | MTHREAD
| | ...
| | framesize=IMIX_v4_1 | wt=2 | rxq=1

| tc09-64B-4t4c-eth-l2bdbasemaclrn-eth-2vhostvr1024-1vm-ndrpdr
| | [Tags] | 64B | 4T4C | MTHREAD
| | ...
| | framesize=${64} | wt=4 | rxq=2

| tc10-1518B-4t4c-eth-l2bdbasemaclrn-eth-2vhostvr1024-1vm-ndrpdr
| | [Tags] | 1518B | 4T4C | MTHREAD
| | ...
| | framesize=${1518} | wt=4 | rxq=2

| tc11-9000B-4t4c-eth-l2bdbasemaclrn-eth-2vhostvr1024-1vm-ndrpdr
| | [Tags] | 9000B | 4T4C | MTHREAD
| | ...
| | framesize=${9000} | wt=4 | rxq=2

| tc12-IMIX-4t4c-eth-l2bdbasemaclrn-eth-2vhostvr1024-1vm-ndrpdr
| | [Tags] | IMIX | 4T4C | MTHREAD
| | ...
| | framesize=IMIX_v4_1 | wt=4 | rxq=2
