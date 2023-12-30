---
{
    "title": "Twelve-Factor App with Amazon ECS and the CDK",
    "description": "Amazon ECS encourages us to adopt practices that conform with the twelve-factor app methodology",
    "image": "v1629464718/AWS_Elastic_Container_Service_h12wlp.png",
    "published": "2021-08-21",
}
---
Every developer should be familiar with the concepts outlined in [The Twelve-Factor App](https://12factor.net/). The twelve-factor app is a 
methodology for building modern SaaS apps.

[Amazon Elastic Container Service](https://aws.amazon.com/ecs/) (ECS) is a great service by AWS that lets us run 
containerised applications with ease. By defining our Infrastructure as Code with the
[AWS CDK](https://docs.aws.amazon.com/cdk/latest/guide/home.html) and by leveraging a 
service like ECS, we are able to easily build twelve-factor applications.

Let's address the main factors of a twelve-factor app that are relevant to ECS and CDK below.

### [III. Config](https://12factor.net/config)
> The twelve-factor app stores config in environment variables (often shortened to env vars or env). Env vars are 
> easy to change between deploys without changing any code; unlike config files, there is little chance of them 
> being checked into the code repo accidentally; and unlike custom config files, or other config mechanisms such as 
> Java System Properties, they are a language- and OS-agnostic standard.
 
ECS lets us define the environment variables and secrets on our
[Container Definition](https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html). This 
container definition lets us define the Docker image for our container, along with any environment variables and 
secrets to inject into that container. An example container definition using the CDK looks something like this

```javascript
const applicationContainer = applicationServiceDefinition.addContainer('app-container', {
  cpu: 256,
  environment: {
    APP_URL: 'https://example.com',
    LOG_CHANNEL: 'stdout',
    LOG_LEVEL: 'debug',
    DB_CONNECTION: 'mysql',
    DB_HOST: db.dbInstanceEndpointAddress,
    DB_PORT: db.dbInstanceEndpointPort,
    CACHE_DRIVER: 'redis',
    REDIS_HOST: redis.attrRedisEndpointAddress,
    REDIS_PASSWORD: 'null',
    REDIS_PORT: '6379',
  },
  image: ContainerImage.fromDockerImageAsset(applicationImage),
  logging: LogDriver.awsLogs({
    logGroup: applicationLogGroup,
    streamPrefix: new Date().toLocaleDateString('en-ZA')
  }),
  memoryLimitMiB: 512,
  secrets: {
    DB_DATABASE: Secret.fromSecretsManager(db.secret, 'dbname'),
    DB_USERNAME: Secret.fromSecretsManager(db.secret, 'username'),
    DB_PASSWORD: Secret.fromSecretsManager(db.secret, 'password'),
    STRIPE_KEY: Secret.fromSecretsManager(stripe, 'STRIPE_KEY'),
    STRIPE_SECRET: Secret.fromSecretsManager(stripe, 'STRIPE_SECRET'),
  },
});
```
In this example, we can see that some of our environment variables are set directly from other resources managed via 
the CDK (db is an RDS instance, and redis is an ElastiCache cluster). The other variables that are hardcoded as 
strings we can easily swap out to reference the 
[AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html).
For example:
        
    const APP_URL = StringParameter.fromStringParameterName(this, 'APP_URL', 'APP_URL').stringValue;

We would then update the APP_URL environment variable in the container definition to reference these value sources 
from the Parameter Store. This means that we can swap out environment variables easily between deploys without 
having to update a single line of code.

Similarly, for Secrets, we can leverage the AWS Secrets Manager and do the exact same thing

    const stripe = SecretManager.fromSecretNameV2(this, 'stripe_keys', 'STRIPE');

Note: Use Parameter Store for configuration (connection strings, log levels, etc.) and Secrets Manager for sensitive 
information (passwords and secret keys)

### [IV. Backing Services](https://12factor.net/backing-services)
> The code for a twelve-factor app makes no distinction between local and third party services. To the app, both are 
> attached resources, accessed via a URL or other locator/credentials stored in the config. A deploy of the 
> twelve-factor app should be able to swap out a local MySQL database with one managed by a third party (such as 
> Amazon RDS) without any changes to the app’s code. Likewise, a local SMTP server could be swapped with a 
> third-party SMTP service (such as Postmark) without code changes. In both cases, only the resource handle in the 
> config needs to change.

When we run an ECS cluster, we are running all our services in individual containers that communicate over the 
network. There is no local database, filesystem or cache. Everything that our application needs to talk to goes via 
the network. CDK lets us easily provision resources such as MySQL or Redis. We've already seen how we can connect 
our application to these services via a Container Definition. 

```javascript
// RDS
const db = new DatabaseInstance(this, 'primary-db', {
  allocatedStorage: 20,
  autoMinorVersionUpgrade: true,
  allowMajorVersionUpgrade: false,
  databaseName: 'example',
  engine: DatabaseInstanceEngine.mysql({
    version: MysqlEngineVersion.VER_8_0_21
  }),
  iamAuthentication: true,
  instanceType: InstanceType.of(InstanceClass.BURSTABLE3, InstanceSize.SMALL),
  maxAllocatedStorage: 250,
  multiAz: false,
  securityGroups: [databaseSecurityGroup],
  vpc,
  vpcSubnets: {
    subnetGroupName: SUBNET_ISOLATED.name
  }
});

// ELASTICACHE
const redisSubnetGroup = new CfnSubnetGroup(this, 'redis-subnet-group', {
    description: 'Redis Subnet Group',
    subnetIds: vpc.isolatedSubnets.map(s => s.subnetId),
    cacheSubnetGroupName: 'RedisSubnetGroup'
});

const redis = new CfnCacheCluster(this, 'redis-cluster', {
    cacheNodeType: 'cache.t3.small',
    cacheSubnetGroupName: redisSubnetGroup.cacheSubnetGroupName,
    clusterName: 'redis-cluster',
    engine: 'redis',
    engineVersion: '6.x',
    numCacheNodes: 1,
    port: 6379,
    vpcSecurityGroupIds: [redisSecurityGroup.securityGroupId]
});

redis.node.addDependency(redisSubnetGroup);
```

### [V. Build, Release, Run](https://12factor.net/build-release-run)
> The twelve-factor app uses strict separation between the build, release, and run stages. For example, it is 
> impossible to make changes to the code at runtime, since there is no way to propagate those changes back to the 
> build stage.
 
### **Build**

CDK lets us reference a Dockerfile that defines how our source code gets built into a Docker image.

```javascript
const applicationImage = new DockerImageAsset(this, 'applicationImage', {
  directory: '..',
  file: './docker/apache/Dockerfile'
});
```
### Release
CDK then tags that image and uploads it to the Elastic Container Registry (ECR)

### Run
In our Config example, we had the following line in our container definition

    image: ContainerImage.fromDockerImageAsset(applicationImage),

This instructs the container where to grab the release from and ensures that this is the release run by ECS. There 
is no server to SSH into and make changes to code at runtime. Code cannot be edited, and in fact, there is no 
"server" to make changes on either. ECS spins up compute resources on-demand and tears it down again on the fly. In 
the event that a new release is broken, ECS can even automatically rollback to a previous release for us by defining 
setting the rollback attribute to true on our circuit breaker.

```javascript
const applicationService = new FargateService(this, 'application-fargate-service', {
  circuitBreaker: {
    rollback: true
  },
  deploymentController: {
    type: DeploymentControllerType.ECS
  },
  taskDefinition: applicationServiceDefinition,
});
```

### [VI. Process](https://12factor.net/processes)
> Twelve-factor processes are stateless and share-nothing. Any data that needs to persist must be stored in a 
> stateful backing service, typically a database.

The reason processes should be stateless and share nothing is so that we can scale our applications horizontally. If 
we have a container that runs our application code, and also has a local cache, it means any request that gets 
routed to another container via our load balancer is going to potentially get a cache miss. Similarly, we are not 
going to have a great user experience if each container has its own database. Someone using our app could save some 
data in one container and then not be able to retrieve it if it gets routed to another one.

Creating load-balanced applications with ECS and CDK is very straightforward.

```javascript
// LOAD BALANCER
const alb = new ApplicationLoadBalancer(this, 'application-ALB', {
  http2Enabled: false,
  internetFacing: true,
  loadBalancerName: 'application',
  vpc,
  vpcSubnets: {
    subnetGroupName: SUBNET_APPLICATION.name
  }
});

// For HTTPS you need to set up an ACM and reference it here
const listener = alb.addListener('alb-target-group', {
  open: true,
  port: 80
});

// Target group to make resources containers discoverable by the application load balancer
const targetGroupHttp = new ApplicationTargetGroup(this, 'alb-target-group', {
  port: 80,
  protocol: ApplicationProtocol.HTTP,
  targetType: TargetType.IP,
  vpc,
});

// Health check for containers to check they were deployed correctly
targetGroupHttp.configureHealthCheck({
  path: '/api/health-check',
  protocol: Protocol.HTTP,
});

// Add target group to listener
listener.addTargetGroups('alb-listener-target-group', {
  targetGroups: [targetGroupHttp],
});

applicationService.attachToApplicationTargetGroup(targetGroupHttp);

const scaleTarget = applicationService.autoScaleTaskCount({
  minCapacity: 1,
  maxCapacity: 10,
});

scaleTarget.scaleOnMemoryUtilization('scale-out-memory-threshold', {
  targetUtilizationPercent: 75
});

scaleTarget.scaleOnCpuUtilization('scale-out-cpu-threshold', {
  targetUtilizationPercent: 75
});
```

### [VIII. Concurrency](https://12factor.net/concurrency)
> In the twelve-factor app, processes are a first class citizen. Processes in the twelve-factor app take strong cues 
> from the unix process model for running service daemons. Using this model, the developer can architect their app 
> to handle diverse workloads by assigning each type of work to a process type. For example, HTTP requests may be 
> handled by a web process, and long-running background tasks handled by a worker process.

This rule is one of the more important rules for us to consider when deploying our application with ECS. If we take 
a traditional web framework like [Laravel](https://laravel.com/) we need to split some functionality out to run in 
separate containers.
 
For example, Laravel has built-in functionality to process queued jobs, or to schedule recurring tasks. In a 
traditional single-server deployment, we would simply deploy our app and start three processes on our server
- apache for handling HTTP requests
- cron for running scheduled tasks
- process for monitoring our queues

With ECS we need to define a specific container for each task and run a single process in each container.

````javascript
const applicationImage = new DockerImageAsset(this, 'applicationImage', {
  directory: '..',
  file: './docker/apache/Dockerfile'
});

const schedulerImage = new DockerImageAsset(this, 'schedulerImage', {
  directory: '..',
  file: './docker/scheduler/Dockerfile'
});

const queueWorkerImage = new DockerImageAsset(this, 'queueWorkerImage', {
  directory: '..',
  file: './docker/queue_worker/Dockerfile'
});
````
In each container, we could reference a start script

    CMD ["/start.sh"]

For a Laravel application, our start script might look like this - we do some pre-caching of config, seed our 
database and then run apache in the foreground

````bash
#!/bin/bash
echo "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI=$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI" > /var/www/html/.env
php artisan cache:clear
php artisan config:cache
php artisan route:cache
php artisan migrate --seed --force

/usr/local/bin/apache2-foreground
````

We'd then run our queue process in another container. Again we need some laravel specific config caching and then 
run the 'php artisan queue:work' command

````bash
#!/bin/bash
echo "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI=$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI" > /var/www/html/.env
php artisan cache:clear
php artisan config:cache

php artisan queue:work --timeout=300
````

Finally, for scheduled jobs 

```bash
### crontab
* * * * * /usr/local/bin/php /var/www/html/artisan schedule:run --verbose --no-interaction > /proc/1/fd/1 2>/proc/1/fd/2

#### Dockerfile
# Copy cron file to the cron.d directory
ADD ./docker/scheduler/crontab /etc/cron.d/scheduler-cron
# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/scheduler-cron
# Apply cron job
RUN crontab /etc/cron.d/scheduler-cron
# Add start script
RUN chmod +x /start.sh

CMD ["/start.sh"]


### start.sh
#!/bin/bash
echo "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI=$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI" >> /etc/environment
php artisan cache:clear
php artisan config:cache
cron -f
```

### [X. Dev/prod parity](https://12factor.net/dev-prod-parity)
> The twelve-factor developer resists the urge to use different backing services between development and production, 
> even when adapters theoretically abstract away any differences in backing services. Differences between backing 
> services mean that tiny incompatibilities crop up, causing code that worked and passed tests in development or 
> staging to fail in production. These types of errors create friction that disincentivizes continuous deployment. 
> The cos  of this friction and the subsequent dampening of continuous deployment is extremely high when considered 
> in aggregate over the lifetime of an application.
 
By using the AWS CDK, and defining all our infrastructure in code, we enforce strict parity between development, 
staging, and production environments. Our infrastructure gets deployed the same way in each environment, the only 
thing that changes is the AWS account it gets deployed to. This ensures we don't get any surprises when shipping our 
code to production - and we should be shipping continuously!

### [XI. Logs](https://12factor.net/logs)
> A twelve-factor app never concerns itself with routing or storage of its output stream. It should not attempt to 
> write to or manage logfiles. Instead, each running process writes its event stream, unbuffered, to stdout. During 
> local development, the developer will view this stream in the foreground of their terminal to observe the app’s 
> behavior.
 
Our containers are constantly being spun up and torn down. We also can't SSH into them to view log files. In a 
previous example, I showed an example Container Definition for an ECS Fargate Service. It defined a log driver like so:

```javascript
const applicationContainer = applicationServiceDefinition.addContainer('app-container', {
  // other config
  environment: {
    // other env
    LOG_LEVEL: 'stdout'
  },
  logging: LogDriver.awsLogs({
    logGroup: applicationLogGroup,
    streamPrefix: new Date().toLocaleDateString('en-ZA')
  }),
});
```

Each container logs to stdout and then ECS uses a built-in log driver to stream those logs to
[AWS Cloudwatch](https://aws.amazon.com/cloudwatch/). That's all we need to do to meet the Log criteria.

## Find Out More
I have a full 80-minute course on ECS using CDK which you can find [here](https://michaeltimbs.gumroad.com/l/BZPcgS)

![Example Architecture](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/Architecture.png)
