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
| Library | resources.libraries.python.InterfaceUtil
| Library | resources.libraries.python.NodePath
| ...
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | NDRCHK
| ... | NIC_Intel-X520-DA2 | ETH | L2XCFWD | BASE | L2XCBASE
| ...
| Suite Setup | Set up 3-node performance topology with DUT's NIC model
| ... | L2 | Intel-X520-DA2
| Suite Teardown | Tear down 3-node performance topology
| ...
| Test Setup | Set up performance test
| Test Teardown | Tear down performance ndrchk test
| ...
| Documentation | *Reference NDR throughput L2XC verify test cases*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 for L2 cross connect.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with L2 cross-
| ... | connect. DUT1 and DUT2 tested with 2p10GE NIC X520 Niantic by Intel.
| ... | *[Ver] TG verification:* In short performance tests, TG verifies
| ... | DUTs' throughput at ref-NDR (reference Non Drop Rate) with zero packet
| ... | loss tolerance. Ref-NDR value is periodically updated acording to
| ... | formula: ref-NDR = 0.9x NDR, where NDR is found in RFC2544 long
| ... | performance tests for the same DUT configuration. Test packets are
| ... | generated by TG on links to DUTs. TG traffic profile contains two L3
| ... | flow-groups (flow-group per direction, 253 flows per flow-group) with
| ... | all packets containing Ethernet header, IPv4 header with IP protocol=61
| ... | and static payload. MAC addresses are matching MAC addresses of the
| ... | TG node interfaces.
| ... | *[Ref] Applicable standard specifications:* RFC2544.

*** Variables ***
# Traffic profile:
| ${traffic_profile} | trex-sl-3n-ethip4-ip4src254

*** Test Cases ***
| tc01-64B-1t1c-eth-l2xcbase-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 64 Byte
| | ... | frames using single trial throughput test at 2x 5.9mpps.
| | [Tags] | 64B | 1T1C | STHREAD
| | ${framesize}= | Set Variable | ${64}
| | ${rate}= | Set Variable | 5.9mpps
| | Given Add '1' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | And Initialize L2 xconnect in 3-node circular topology
| | Then Traffic should pass with no loss | ${perf_trial_duration} | ${rate}
| | ... | ${framesize} | ${traffic_profile}

| tc02-1518B-1t1c-eth-l2xcbase-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 1518 Byte
| | ... | frames using single trial throughput test at 2x 812743pps.
| | [Tags] | 1518B | 1T1C | STHREAD
| | ${framesize}= | Set Variable | ${1518}
| | ${rate}= | Set Variable | 812743pps
| | Given Add '1' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | And Initialize L2 xconnect in 3-node circular topology
| | Then Traffic should pass with no loss | ${perf_trial_duration} | ${rate}
| | ... | ${framesize} | ${traffic_profile}

| tc03-9000B-1t1c-eth-l2xcbase-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 9000 Byte
| | ... | frames using single trial throughput test at 2x 138580pps.
| | [Tags] | 9000B | 1T1C | STHREAD
| | ${framesize}= | Set Variable | ${9000}
| | ${rate}= | Set Variable | 138580pps
| | Given Add '1' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Apply startup configuration on all VPP DUTs
| | And Initialize L2 xconnect in 3-node circular topology
| | Then Traffic should pass with no loss | ${perf_trial_duration} | ${rate}
| | ... | ${framesize} | ${traffic_profile}

| tc04-64B-2t2c-eth-l2xcbase-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 64 Byte
| | ... | frames using single trial throughput test at 2x 10.4mpps.
| | [Tags] | 64B | 2T2C | MTHREAD
| | ${framesize}= | Set Variable | ${64}
| | ${rate}= | Set Variable | 10.4mpps
| | Given Add '2' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | And Initialize L2 xconnect in 3-node circular topology
| | Then Traffic should pass with no loss | ${perf_trial_duration} | ${rate}
| | ... | ${framesize} | ${traffic_profile}

| tc05-1518B-2t2c-eth-l2xcbase-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 1518 Byte
| | ... | frames using single trial throughput test at 2x 812743pps.
| | [Tags] | 1518B | 2T2C | MTHREAD
| | ${framesize}= | Set Variable | ${1518}
| | ${rate}= | Set Variable | 812743pps
| | Given Add '2' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | And Initialize L2 xconnect in 3-node circular topology
| | Then Traffic should pass with no loss | ${perf_trial_duration} | ${rate}
| | ... | ${framesize} | ${traffic_profile}

| tc06-9000B-2t2c-eth-l2xcbase-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 9000 Byte
| | ... | frames using single trial throughput test at 2x 138580pps.
| | [Tags] | 9000B | 2T2C | MTHREAD
| | ${framesize}= | Set Variable | ${9000}
| | ${rate}= | Set Variable | 138580pps
| | Given Add '2' worker threads and '1' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Apply startup configuration on all VPP DUTs
| | And Initialize L2 xconnect in 3-node circular topology
| | Then Traffic should pass with no loss | ${perf_trial_duration} | ${rate}
| | ... | ${framesize} | ${traffic_profile}

| tc07-64B-4t4c-eth-l2xcbase-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Verify ref-NDR for 64 Byte
| | ... | frames using single trial throughput test at 2x 10.4mpps.
| | [Tags] | 64B | 4T4C | MTHREAD
| | ${framesize}= | Set Variable | ${64}
| | ${rate}= | Set Variable | 10.4mpps
| | Given Add '4' worker threads and '2' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | And Initialize L2 xconnect in 3-node circular topology
| | Then Traffic should pass with no loss | ${perf_trial_duration} | ${rate}
| | ... | ${framesize} | ${traffic_profile}

| tc08-1518B-4t4c-eth-l2xcbase-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Verify ref-NDR for 1518 Byte
| | ... | frames using single trial throughput test at 2x 812743pps.
| | [Tags] | 1518B | 4T4C | MTHREAD
| | ${framesize}= | Set Variable | ${1518}
| | ${rate}= | Set Variable | 812743pps
| | Given Add '4' worker threads and '2' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | And Initialize L2 xconnect in 3-node circular topology
| | Then Traffic should pass with no loss | ${perf_trial_duration} | ${rate}
| | ... | ${framesize} | ${traffic_profile}

| tc09-9000B-4t4c-eth-l2xcbase-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Verify ref-NDR for 9000 Byte
| | ... | frames using single trial throughput test at 2x 138580pps.
| | [Tags] | 9000B | 4T4C | MTHREAD
| | ${framesize}= | Set Variable | ${9000}
| | ${rate}= | Set Variable | 138580pps
| | Given Add '4' worker threads and '2' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Apply startup configuration on all VPP DUTs
| | And Initialize L2 xconnect in 3-node circular topology
| | Then Traffic should pass with no loss | ${perf_trial_duration} | ${rate}
| | ... | ${framesize} | ${traffic_profile}
