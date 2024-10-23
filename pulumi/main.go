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

		vnet, err := network.NewVirtualNetwork(ctx, "k3s-cluster-vnet", &network.VirtualNetworkArgs{
			AddressSpace: &network.AddressSpaceArgs{
				AddressPrefixes: pulumi.StringArray{
					pulumi.String("10.0.0.0/16"),
				},
			},
			FlowTimeoutInMinutes: pulumi.Int(10),
			Location:             pulumi.String(rg.Location),
			ResourceGroupName:    pulumi.String(rg.Name),
		})
		if err != nil {
			return err
		}

		_, err = network.NewSubnet(ctx, "cluster-subnet", &network.SubnetArgs{
			AddressPrefix:      pulumi.String("10.0.0.0/16"),
			ResourceGroupName:  pulumi.String(rg.Name),
			VirtualNetworkName: vnet.Name,
		})
		if err != nil {
			return err
		}

		return nil
	})
}
