# Terraform module to create Client VPN Endpoint on AWS

This was forked from [achuchulev/terraform-aws-client-vpn-endpoint](https://github.com/achuchulev/terraform-aws-client-vpn-endpoint); please read the README from there.

# What I was trying to change

My plan was to have a terraform module that creates all the certs and improves on some of the null-resources in the forked repo.

I also wanted to add these features/make these changes:

* Multiple subnets can be specified.
* Remove all the requirements for aws credentials, region, etc, so it can be used as a terraform module and inherit these from the caller.
* Add a prefix so the module can be run multiple times into one aws account for differences instances of the same stack. Eg `k1-`.
* Change the domain to be a domain_suffix so the prefix and the domain_suffix can be added together to create a fqdn; eg `k1.example.net`.
* Server and client certs in acm will have the fqdn so you can see what certs are for what instances of the resource; eg `server.k1.example.net` and `client.k1.example.net` are for the `k1` prefix deployment/stack.
* Improve the scripts and reduce complexity with the cert dir, etc. For example the `client-config.ovpn` file is not created properly.
* Fix any issues or bugs.

# Issues I encountered

I was unable to find a way to generate the easy rsa certs in terraform, and then feed them into resource `aws_acm_certificate`. The issue is if you are loading the attributes into the resource `aws_acm_certificate` using `file`, it expects the files to be there. The original creator of this repo did not elude to this issue, and just advised to run the script to generate the certs before running the terraform. I was unable to find any terraform code to create the easy rsa certs.

Another issue that concerned me is lack of terraform resources to create all the other parts for the stack; these still need `null-resources` as coded up by the original author. I am not sure when these will be available.

Another issue is it takes way too long to create the Client Vpn. Inessence we are creating an openvpn service. I think it would be much quicker (and cheaper) to use Openvpn on a small ec2 instance, or using openvpn on kubernetes, etc. I suppose what I am saying is this aws service is not particularly easy or quick to setup. I suspect the cost of a small ec2 instance will probably be cheaper to run than paying for the client vpn service.

Thus I decided to commit the working config I have, not progress this further, and maybe someone else may find it useful, or wish to develop it further. I will go with a kubernetes openvpn solution (there is a helm3 chart to deploy it), and also have a ec2 openvpn solution for backup (should kubernetes be broken).

# Prerequisites

* git
* terraform ( ~> 0.12 )
* AWS subscription
* VPC with Internet GW and a subnet having route assosiated with the IGW (i.e a public subnet)

# How to use

## vpn-client and generate-certs in different tf files

The generates certs functionality, which does not work and is not run, is called `generate-certs.tf_unused`.

The creation of the client vpn is called `client-vpn.tf`.

To me it made sense to split these up; eg keep work I have done so far; might be useful for someone.

## AWS environment is set by calling terraform or via environment variables

This includes region. See [aws docs](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html) on the env variables such as AWS_PROFILE, AWS_DEFAULT_REGION, etc. Most people use aws profiles to manage multiple aws accounts. Tools like `awsume` make managing multiple accounts and assumed roles easy.

## Use the module call in the example dir

To emulate a module, you can use the terraform config in the `examples` directory. Specifically [main.tf](examples/main.tf).

Also check the [variables.tf](variables.tf) for what can be set.

#### Generate Server and Client Certificates and Keys


The script is `scripts/gen_acm_cert.sh`, and takes args `<dir> <prefix>.<domain-suffix> # eg k1.example.net`

Using the `example` module config; eg module source is `../`:

```
$ cd example
$ ../scripts/gen_acm_cert.sh `pwd` k1.example.net # eg k1.example.net
```

If your module source is github, try:

```
$ cd example
$ ./.terraform/modules/<module-name>/scripts/gen_acm_cert.sh `pwd` k1.example.net # eg k1.example.net
```

Either way certs will be put in the pwd `./certs/`.

Script will:
* make a `certs` directory in the current directory
* create private Certificate Authority (CA).
* issue server certificate chain.
* issue client certificate chain.
* cleanup after itself.
  
Note: This is based on official AWS tutorial described [here](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/authentication-authorization.html#mutual)

### Deploy Client VPN

Still in the `example` directory.

```
$ terraform init
$ terraform plan
$ terraform apply
```

`Terraform apply` will:
* upload server certificate to AWS Certificate Manager (ACM)
* upload client certificate to AWS Certificate Manager (ACM)
* create new Client VPN Endpoint on AWS 
* make VPN network association with specified VPC subnet
* authorize all clients vpn ingress
* create new route to allow Internet access for VPN clients
* export client config file `client-config.ovpn` in the root

#### Outputs

| Name  |	Description 
| ----- | ----------- 
| client_vpn_endpoint_id | Client VPN Endpoint id


### Import client config file in your prefered openvpn client and connect
