---
title: "How to use a launch template in AWS Batch compute environment with custom user_data file"
date: 2020-02-22T22:31:07+01:00
draft: true
author: "Tommaso Visconti"
categories: ["terraform", "aws"]
description: ""
image: "/images/2020/02/user_data-file-and-launch-template-in-aws-batch.jpeg"
slug: "user_data-file-and-launch-template-in-aws-batch"
tags: ["terraform", "aws", "batch"]
---

[AWS Batch](https://aws.amazon.com/it/batch/) is a service from AWS to run batch processes on custom compute environments.

Among all the services I've used on AWS, Batch is, in my opinion, the most rough and less integrated with [Terraform](https://www.terraform.io/). One example of how Batch isn't the most shining service in the AWS world is the integration between the Batch compute environment and the EC2 launch template.

<!--more-->

A launch template is a "description" of the instance(s) we want to execute within a batch run. Using a launch template is handy because we can specify there all the features of the EC2 instances, overriding something directly in the compute environment in case we need it (but avoiding adding all instance features in batch).

An important part of the launch template is the `user_data` shell script, which is a script that is executed in the instances upon launch. That script, used with any other AWS service (ECS is an example) is a standard shell script.
This isn't true with Batch, and debugging the failure of the compute environment is all but easy or intuitive.

So I'm writing this post to help anyone having the same headaches I had while adding the launch template to a Batch environment :)

Adding a launch template to the compute environment in Terraform is as simple as:

```terraform
resource "aws_batch_compute_environment" "my_compute_environment" {
  compute_environment_name = "my_compute_env"
  compute_resources {
    launch_template {
      launch_template_id = aws_launch_template.my_launch_template.id
      version            = "$Latest"
    }
  }
}
```

And the `user_data` file can be added to the launch template with:

```terraform
resource "aws_launch_template" "my_launch_template" {
  user_data = base64encode(data.template_file.userdata.rendered)
}

data "template_file" "userdata" {
  template = "${file("${path.module}/user_data.sh")}"
  vars = {
      // Any var you need to pass to the script
  }
}
```

The content of a standard `user_data` shell script is something like:

```bash
#!/bin/bash
# Do something at startup
```

Unfortunately this doesn't work. The solution is to incapsulate the script in a `multipart/mixed` boundary section, but please don't ask why :)


```bash
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
# Do something at startup

--==MYBOUNDARY==
```

Et voilà, the compute environment will now work.
