# Copyright (c) 2016 Cisco and/or its affiliates.
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

"""L2 Utilities Library."""

from robot.api.deco import keyword
from resources.libraries.python.topology import Topology
from resources.libraries.python.VatExecutor import VatExecutor, VatTerminal


class L2Util(object):
    """Utilities for l2 configuration"""

    @staticmethod
    def vpp_add_l2fib_entry(node, mac, interface, bd_id):
        """ Create a static L2FIB entry on a vpp node.

        :param node: Node to add L2FIB entry on.
        :param mac: Destination mac address.
        :param interface: Interface name.
        :param bd_id: Bridge domain id.
        :type node: dict
        :type mac: str
        :type interface: str
        :type bd_id: int
        """
        sw_if_index = Topology.get_interface_sw_index(node, interface)
        VatExecutor.cmd_from_template(node, "add_l2_fib_entry.vat",
                                      mac=mac, bd=bd_id,
                                      interface=sw_if_index)

    @staticmethod
    def create_l2_bd(node, bd_id, flood=1, uu_flood=1, forward=1, learn=1,
                     arp_term=0):
        """Create a l2 bridge domain on the chosen VPP node

        Execute "bridge_domain_add_del bd_id {bd_id} flood {flood} uu-flood 1
        forward {forward} learn {learn} arp-term {arp_term}" VAT command on
        the node.

        :param node: node where we wish to crate the l2 bridge domain
        :param bd_id: bridge domain index number
        :param flood: enable flooding
        :param uu_flood: enable uu_flood
        :param forward: enable forwarding
        :param learn: enable mac address learning to fib
        :param arp_term: enable arp_termination
        :type node: dict
        :type bd_id: int
        :type flood: bool
        :type uu_flood: bool
        :type forward: bool
        :type learn: bool
        :type arp_term:bool
        """
        VatExecutor.cmd_from_template(node, "l2_bd_create.vat",
                                      bd_id=bd_id, flood=flood,
                                      uu_flood=uu_flood, forward=forward,
                                      learn=learn, arp_term=arp_term)

    @staticmethod
    def add_interface_to_l2_bd(node, interface, bd_id, shg=0):
        """Add a interface to the l2 bridge domain.

        Get SW IF ID and add it to the bridge domain.

        :param node: node where we want to execute the command that does this
        :param interface: interface name
        :param bd_id: bridge domain index number to add Interface name to
        :param shg: split horizon group
        :type node: dict
        :type interface: str
        :type bd_id: int
        :type shg: int
        """
        sw_if_index = Topology.get_interface_sw_index(node, interface)
        L2Util.add_sw_if_index_to_l2_bd(node, sw_if_index, bd_id, shg)

    @staticmethod
    def add_sw_if_index_to_l2_bd(node, sw_if_index, bd_id, shg=0):
        """Add interface with sw_if_index to l2 bridge domain.

        Execute the "sw_interface_set_l2_bridge sw_if_index {sw_if_index}
        bd_id {bd_id} shg {shg} enable" VAT command on the given node.

        :param node: node where we want to execute the command that does this
        :param sw_if_index: interface index
        :param bd_id: bridge domain index number to add SW IF ID to
        :param shg: split horizon group
        :type node: dict
        :type sw_if_index: int
        :type bd_id: int
        :type shg: int
        :return:
        """
        VatExecutor.cmd_from_template(node, "l2_bd_add_sw_if_index.vat",
                                      bd_id=bd_id, sw_if_index=sw_if_index,
                                      shg=shg)

    @staticmethod
    @keyword('Create dict used in bridge domain template file for node '
             '"${node}" with links "${link_names}" and bd_id "${bd_id}"')
    def create_bridge_domain_vat_dict(node, link_names, bd_id):
        """Create dictionary that can be used in l2 bridge domain template.

        :param node: node data dictionary
        :param link_names: list of names of links the bridge domain should be
        connecting
        :param bd_id: bridge domain index number
        :type node: dict
        :type link_names: list
        :return: dictionary used to generate l2 bridge domain VAT configuration
        from template file
        The resulting dictionary looks like this:
        'interface1': interface name of first interface
        'interface2': interface name of second interface
        'bd_id': bridge domain index
        """
        bd_dict = Topology().get_interfaces_by_link_names(node, link_names)
        bd_dict['bd_id'] = bd_id
        return bd_dict

    @staticmethod
    def vpp_add_l2_bridge_domain(node, bd_id, port_1, port_2, learn=True):
        """Add L2 bridge domain with 2 interfaces to the VPP node.

        :param node: Node to add L2BD on.
        :param bd_id: Bridge domain ID.
        :param port_1: First interface name added to L2BD.
        :param port_2: Second interface name added to L2BD.
        :param learn: Enable/disable MAC learn.
        :type node: dict
        :type bd_id: int
        :type port_1: str
        :type port_2: str
        :type learn: bool
        """
        sw_if_index1 = Topology.get_interface_sw_index(node, port_1)
        sw_if_index2 = Topology.get_interface_sw_index(node, port_2)
        VatExecutor.cmd_from_template(node,
                                      'l2_bridge_domain.vat',
                                      sw_if_id1=sw_if_index1,
                                      sw_if_id2=sw_if_index2,
                                      bd_id=bd_id,
                                      learn=int(learn))

    @staticmethod
    def vpp_setup_bidirectional_cross_connect(node, interface1, interface2):
        """Create bidirectional cross-connect between 2 interfaces on vpp node.

        :param node: Node to add bidirectional cross-connect
        :param interface1: first interface
        :param interface2: second interface
        :type node: dict
        :type interface1: str
        :type interface2: str
        """
        sw_iface1 = Topology().get_interface_sw_index(node, interface1)
        sw_iface2 = Topology().get_interface_sw_index(node, interface2)
        with VatTerminal(node) as vat:
            vat.vat_terminal_exec_cmd_from_template('l2_xconnect.vat',
                                                    interface1=sw_iface1,
                                                    interface2=sw_iface2)
            vat.vat_terminal_exec_cmd_from_template('l2_xconnect.vat',
                                                    interface1=sw_iface2,
                                                    interface2=sw_iface1)
