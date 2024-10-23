package main

import (
	network "github.com/pulumi/pulumi-azure-native-sdk/network/v2"
	"github.com/pulumi/pulumi-azure-native-sdk/resources/v2"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		// Get the existing resource group
		rg, err := resources.LookupResourceGroup(ctx, &resources.LookupResourceGroupArgs{
			ResourceGroupName: "k3s-cluster",
		})
		if err != nil {
			return err
		}

		rgName := pulumi.String(rg.Name)

		vnet, err := network.NewVirtualNetwork(ctx, "k3s-cluster-vnet", &network.VirtualNetworkArgs{
			AddressSpace: &network.AddressSpaceArgs{
				AddressPrefixes: pulumi.StringArray{
					pulumi.String("10.0.0.0/16"),
				},
			},
			FlowTimeoutInMinutes: pulumi.Int(10),
			Location:             pulumi.String(rg.Location),
			ResourceGroupName:    rgName,
		})
		if err != nil {
			return err
		}

		subnet, err := network.NewSubnet(ctx, "k3s-cluster-subnet", &network.SubnetArgs{
			AddressPrefix:      pulumi.String("10.0.0.0/16"),
			ResourceGroupName:  rgName,
			VirtualNetworkName: vnet.Name,
		})
		if err != nil {
			return err
		}

		// Network Interface (NIC)
		_, err = network.NewNetworkInterface(ctx, "k3s-master-nic", &network.NetworkInterfaceArgs{
			ResourceGroupName: rgName,
			IpConfigurations: network.NetworkInterfaceIPConfigurationArray{
				&network.NetworkInterfaceIPConfigurationArgs{
					Name:                      pulumi.String("internal"),
					Subnet:                    &network.SubnetTypeArgs{Id: subnet.ID()},
					PrivateIPAllocationMethod: pulumi.String("Dynamic"),
				},
			},
		})
		if err != nil {
			return err
		}

		// Public IP (optional)
		_, err = network.NewPublicIPAddress(ctx, "k3s-master-publicip", &network.PublicIPAddressArgs{
			ResourceGroupName:        rgName,
			PublicIPAddressVersion:   pulumi.String("IPv4"),
			PublicIPAllocationMethod: pulumi.String("Dynamic"),
		})
		if err != nil {
			return err
		}

		return nil
	})
}
