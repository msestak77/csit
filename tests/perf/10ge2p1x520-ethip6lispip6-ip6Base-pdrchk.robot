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
| Resource | resources/libraries/robot/lisp/lisp_static_adjacency.robot
| Variables | resources/test_data/lisp/performance/lisp_static_adjacency.py
| ...
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | PDRCHK
| ... | NIC_Intel-X520-DA2 | IP6FWD | ENCAP | LISP | IP6UNRLAY | IP6OVRLAY
| ...
| Suite Setup | Set up 3-node performance topology with DUT's NIC model
| ... | L3 | Intel-X520-DA2
| Suite Teardown | Tear down 3-node performance topology
| ...
| Test Setup | Set up performance test
| Test Teardown | Performance pdrchk test teardown
| ...
| Documentation | *Reference PDR throughput Lisp tunnel verify test cases*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology\
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv6-LISP-IPv6 on DUT1-DUT2,\
| ... | Eth-IPv6-ICMPv6 on TG-DUTn for IPv6 routing over LISPoIPv6 tunnel.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with IPv6\
| ... | routing and static routes. LISPoIPv6 tunnel is configured\
| ... | between DUT1 and DUT2. DUT1 and DUT2 tested with 2p10GE NIC X520\
| ... | Niantic by Intel.
| ... | *[Ver] TG verification:* In short performance tests, TG verifies\
| ... | DUTs' throughput at ref-PDR (reference Non Drop Rate) with zero packet\
| ... | loss tolerance. Ref-PDR value is periodically updated acording to\
| ... | formula: ref-PDR = 0.9x PDR, where PDR is found in RFC2544 long\
| ... | performance tests for the same DUT confiiguration. Test packets are\
| ... | generated by TG on links to DUTs. TG traffic profile contains two L3\
| ... | flow-groups (flow-group per direction, 253 flows per flow-group) with\
| ... | all packets containing Ethernet header, IPv6 header with\
| ... | IP protocol=61 and generated payload.
| ... | *[Ref] Applicable standard specifications:* RFC2544.

*** Variables ***
# Traffic profile:
| ${traffic_profile} | trex-sl-3n-ethip6-ip6src253

*** Keywords ***
| Check PDR for Lisp IPv6 over IPv6 forwarding
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with ${wt} thread, ${wt} phy core,\
| | ... | ${rxq} receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for ${framesize} Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Arguments] | ${framesize} | ${rate} | ${wt} | ${rxq}
| | ...
| | # Test Variables required for test and test teardown
| | Set Test Variable | ${framesize}
| | Set Test Variable | ${rate}
| | ${get_framesize}= | Get Frame Size | ${framesize}
| | ...
| | Given Add '${wt}' worker threads and '${rxq}' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Run Keyword If | ${get_framesize} < ${1522}
| | ... | Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize LISP IPv6 forwarding in 3-node circular topology
| | ... | ${dut1_to_dut2_ip6} | ${dut1_to_tg_ip6} | ${dut2_to_dut1_ip6}
| | ... | ${dut2_to_tg_ip6} | ${prefix6}
| | And Configure LISP topology in 3-node circular topology
| | ... | ${dut1} | ${dut1_if2} | ${NONE}
| | ... | ${dut2} | ${dut2_if1} | ${NONE}
| | ... | ${duts_locator_set} | ${dut1_ip6_eid} | ${dut2_ip6_eid}
| | ... | ${dut1_ip6_static_adjacency} | ${dut2_ip6_static_adjacency}
| | Then Traffic should pass with partial loss | ${perf_trial_duration}
| | ... | ${rate} | ${framesize} | ${traffic_profile}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

*** Test Cases ***
| tc01-78B-1t1c-ethip6lispip6-ip6base-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 78 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 78B | 1T1C | STHREAD
| | ...
| | [Template] | Check PDR for Lisp IPv6 over IPv6 forwarding
| | framesize=${78} | rate=1.56mpps | wt=1 | rxq=1

| tc02-1460B-1t1c-ethip6lispip6-ip6base-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 1460 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 1460B | 1T1C | STHREAD
| | ...
| | [Template] | Check PDR for Lisp IPv6 over IPv6 forwarding
| | framesize=${1460} | rate=740000pps | wt=1 | rxq=1

| tc03-9000B-1t1c-ethip6lispip6-ip6base-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 9000 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 9000B | 1T1C | STHREAD
| | ...
| | [Template] | Check PDR for Lisp IPv6 over IPv6 forwarding
| | framesize=${9000} | rate=120000pps | wt=1 | rxq=1

| tc04-78B-2t2c-ethip6lispip6-ip6base-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 2 thread, 2 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 78 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 78B | 2T2C | MTHREAD
| | ...
| | [Template] | Check PDR for Lisp IPv6 over IPv6 forwarding
| | framesize=${78} | rate=3.2mpps | wt=2 | rxq=1

| tc05-1460B-2t2c-ethip6lispip6-ip6base-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 2 threads, 2 phy cores,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 1460 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 1460B | 2T2C | MTHREAD
| | ...
| | [Template] | Check PDR for Lisp IPv6 over IPv6 forwarding
| | framesize=${1460} | rate=740000pps | wt=2 | rxq=1

| tc06-9000B-2t2c-ethip6lispip6-ip6base-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 2 threads, 2 phy cores,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 9000 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 9000B | 2T2C | MTHREAD
| | ...
| | [Template] | Check PDR for Lisp IPv6 over IPv6 forwarding
| | framesize=${9000} | rate=120000pps | wt=2 | rxq=1

| tc07-78B-4t4c-ethip6lispip6-ip6base-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 4 threads, 4 phy cores,\
| | ... | 2 receive queues per NIC port.
| | ... | [Ver] Verify ref-NDR for 78 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 78B | 4T4C | MTHREAD
| | ...
| | [Template] | Check PDR for Lisp IPv6 over IPv6 forwarding
| | framesize=${78} | rate=3.2mpps | wt=4 | rxq=2

| tc08-1460B-4t4c-ethip6lispip6-ip6base-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 4 threads, 4 phy cores,\
| | ... | 2 receive queues per NIC port.
| | ... | [Ver] Verify ref-NDR for 1460 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 1460B | 4T4C | MTHREAD
| | ...
| | [Template] | Check PDR for Lisp IPv6 over IPv6 forwarding
| | framesize=${1460} | rate=740000pps | wt=4 | rxq=2

| tc09-9000B-4t4c-ethip6lispip6-ip6base-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 4 threads, 4 phy cores,\
| | ... | 2 receive queues per NIC port.
| | ... | [Ver] Verify ref-NDR for 9000 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 9000B | 4T4C | MTHREAD
| | ...
| | [Template] | Check PDR for Lisp IPv6 over IPv6 forwarding
| | framesize=${9000} | rate=120000pps | wt=4 | rxq=2
