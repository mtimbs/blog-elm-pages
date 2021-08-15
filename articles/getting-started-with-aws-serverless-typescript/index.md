---
{
    "title": "Get Started With AWS, Serverless, and TypeScript",
    "description": "A starter template for new serverless projects with Typescript.",
    "image": "v1629197720/serverless-header_pe54bf.png",
    "published": "2020-03-01",
}
---
About five months ago, I got thrown head first into the world of serverless when I joined the team at [fleet.space](http://fleet.space) to build cloud infrastructure to support their nano-satellite constellation and industrial IoT network.

I really struggled to find a comprehensive guide on how to build new services with TypeScript, so here I am writing the one I wish I had. We won’t go through any example code — we’ll just focus on building up a robust base template you can reuse for all your services.

The first thing we’re going to do is install the [Serverless Framework](https://serverless.com/framework/docs/). I find it has better support than the official AWS SAM templates.

First, lets install Serverless as a global dependency on our system via npm i -g serverless. Next, we’ll create a project, mkdir typescript-serverless. Inside that directory, let’s scaffold out a new Serverless template with the following command:

```bash
sls create --template aws-nodejs-typescript
```

This will generate a bare-bones template with TypeScript, but it’s missing a lot of powerful configuration I use over and over again. So let’s set some of these things up. If you don’t use VS Code, go ahead and delete the pesky VS Code directory this template initialises, and then run npm i to install the base dependencies of the Serverless Framework.

## Serverless Plugins

The Serverless Framework has one advantage over SAM in that there are many community plugins built around it to help you do things (and you can build your own, if needed). It’s very extensible. Plugins I use in almost every service are:

* [serverless-iam-roles-per-function](https://github.com/functionalone/serverless-iam-roles-per-function#readme)

This plugin allows you to define IAM permissions at a function level instead of the default project level. If only one function needs to touch DynamoDB then we don't need to give them all access.

* [serverless-create-global-dynamodb-table](https://github.com/rrahul963/serverless-create-global-dynamodb-table)

Multi-region deploys are essentially free in the serverless world (compared to containers/ec2 anyway). The only complexity is keeping DynamoDB in sync. This can be done with a global table.

* [serverless-offline](https://github.com/dherault/serverless-offline)

This one I don't always use these days but it's only a dev dependency and handy to have. It will let you invoke your lambda API locally.

* [serverless-prune-plugin](https://github.com/claygregory/serverless-prune-plugin)

This is a sneaky risk with serverless, especially if you deploy frequently. Lambda will version each function you deploy and there is a hard storage limit to how many you can store. This plugin will prune old versions that aren't needed and prevent that subtle error hitting your production environment.

```bash
npm i -D serverless-iam-roles-per-function serverless-create-global-dynamodb-table serverless-offline serverless-prune-plugin
```

We’ll also add [aws-sdk](https://github.com/aws/aws-sdk-js) and [aws-lambda](https://github.com/awspilot/cli-lambda-deploy) 
```bash 
npm i aws-sdk aws-lambda.
```

### Lambda Powertools

One thing I really struggled with when I stepped into the world of serverless was observability and traceability. Debugging across service boundaries and even infrastructure within boundaries (Lambda > SQS > Lambda > Kinesis > Lambda > DynamoDB, etc.) was a pain. Thankfully I came across a great set of [powertools](https://github.com/getndazn/dazn-lambda-powertools) for Lambda that are a must-have in any service.

* @dazn/lambda-powertools-cloudwatchevents-client

* @dazn/lambda-powertools-correlation-ids

* @dazn/lambda-powertools-logger

* @dazn/lambda-powertools-pattern-basic

* @dazn/lambda-powertools-lambda-client

* @dazn/lambda-powertools-sns-client

* @dazn/lambda-powertools-sqs-client

* @dazn/lambda-powertools-dynamodb-client

* @dazn/lambda-powertools-kinesis-client

I just import all of these and let webpack tree shaking worry about getting rid of what I’m not using.

```bash
npm i @dazn/lambda-powertools-cloudwatchevents-client @dazn/lambda-powertools-correlation-ids @dazn/lambda-powertools-logger @dazn/lambda-powertools-pattern-basic @dazn/lambda-powertools-lambda-client @dazn/lambda-powertools-sns-client @dazn/lambda-powertools-sqs-client @dazn/lambda-powertools-dynamodb-client @dazn/lambda-powertools-kinesis-client
```

## Linting

The next important thing I can’t live without in a codebase is linting. ESLint is one of the biggest crutches I use everyday. Let’s configure it to work with TypeScript and the Serverless Framework. We’ll need the following dev dependencies.

* [eslint](https://github.com/eslint/eslint)

* [eslint-config-airbnb-base](https://github.com/airbnb/typescript)

* [typescript-eslint](https://github.com/typescript-eslint/typescript-eslint)

* [eslint-plugin-import](https://github.com/benmosher/eslint-plugin-import)

* [@typescript-eslint/eslint-plugin](https://github.com/typescript-eslint/typescript-eslint)

* [@typescript/eslint-parser](https://github.com/typescript-eslint/typescript-eslint)

* [eslint-import-resolver-alias](https://github.com/johvin/eslint-import-resolver-alias)

* [eslint-plugin-module-resolver](https://github.com/HeroProtagonist/eslint-plugin-module-resolver)

```bash
npm i -D eslint eslint-config-airbnb-base typescript-eslint eslint-plugin-import eslint-import-resolver-alias eslint-plugin-module-resolver @typescript-eslint/eslint-plugin @typescript-eslint/parser
```

Now, we need to create an .eslintrc.json config file to define our rules. I like the following rules. This gist also includes some alias mapping for some module aliases we’ll set up at the end and some Jest config we’ll set up in a second.

`gist:fdcc35ae78bece7b6bebf74fb90d8a85`


I’ll also tweak my tsconfig file to add inlineSource, esModuleInterop, sourceRoot, and baseUrl. The following gist also pre-populates some module aliasing information we’ll set up later. You can comment out anything in paths for now, if you want.

`gist:5199c84502e82e2f2834505d2e86c71a`

### Testing

I’ll write tests for every service so it makes sense to configure a test runner in our base template. I personally like [Jest](https://jestjs.io/), so we’ll set that up.

Once again, we’ll need to fill the the black hole of our node_modules with some npm dev dependencies.

* jest

* babel-jest

* @babel/core

* @babel/preset-env

* @babel/preset-typescript

```bash
npm i -D jest babel-jest @babel/core @babel/preset-env @babel/preset-typescript
```

Make sure that Jest is configured as a plugin in your .eslintrc.json and that you set jest/globals under env (if you copied the gist above, you’ll have this in there already).

We need to create a Babel .config for Jest to work.

`gist:b248d49bc907ffdb03d42c1eab6a8b74`

At this point, we should check to see if Jest is working and if it’s configured correctly. Lets create a tests directory and add an example test. Create a test file, and let’s add a dummy test, tests/example.test.ts.

```typescript
describe('who tests the tests?', () => {
  it('can run a test', () => {
    expect.hasAssertions();
    expect(1).toBe(1);
  });
});
```

If you’re using WebStorm, you can hit Ctrl+Shift+R to run this test straight from your IDE. Otherwise, let’s go update our package.json to add a test script (and a lint and TS compile check while we’re there).

In your package.json file, update the scripts section to include the following:

```json
"scripts": {
  "test": "NODE_ENV=test ./node_modules/.bin/jest --ci --verbose",
  "lint": "eslint . --ext .js,.jsx,.ts,.tsx",
  "buildtest": "tsc --noEmit"
 },
```

I generally run all of these in CI/CD pipelines to prevent bad code from hitting production. Now, you can run npm run test from your console to run the test suite. Hopefully, your test suite runs and passes. Ideally, your IDE won’t be throwing linting errors at you in your example.test.ts file either.

While we’re here, run npm run lint, and let’s see if there are any linting errors with the default template. You’ll likely get some errors with webpack.config and the handler.ts file that was autoscaffolded. Let’s clear these up.

At the top of your webpack.config file, add `*/* eslint-disable @typescript-eslint/no-var-requires */*` and uncomment out the Fork TS Checker Webpack Plugin defaults that came with the template. That should solve that file.

For the handler.ts file, just go remove the unused context-function signature from the hello function.

## Code goes in /src

One convention I like is putting all our domain logic inside a /src directory and leaving the root for the config (and /tests). Create a /src directory, and move the handler.ts file inside of the /src directory.

If you decide to adopt this convention, you’ll need to go to serverless.yml and update the path for the handler to src/handler.hello.

Let’s configure our Serverless plugin while we’re in the serverless.yml file.

```yaml
    service:
      name: typescript-serverless
    
    ...
    
    plugins:
      - serverless-offline
      - serverless-webpack
      - serverless-iam-roles-per-function
      - serverless-create-global-dynamodb-table
      - serverless-prune-plugin
    
    ...

```

At this point, you should be able to run sls offline in your terminal and have a clean compile and build launching a Serverless offline endpoint.

```bash
    ➜  typescript-serverless git:(master) ✗ sls offline
    Serverless: Bundling with Webpack...
    Time: 398ms
    Built at: 27/02/2020 11:24:42 pm
      Asset      Size       Chunks             Chunk Names
      src/handler.js  6.33 KiB  src/handler  [emitted]  src/handler
      Entrypoint src/handler = src/handler.js
      [./src/handler.ts] 316 bytes {src/handler} [built]
      [source-map-support/register] external "source-map-support/register" 42 bytes {src/handler} [built]
    Serverless: Watching for changes...
    Serverless: Starting Offline: dev/us-east-1.
    
    Serverless: Routes for hello:
    Serverless: GET /hello
    Serverless: POST /{apiVersion}/functions/typescript-serverless-dev-hello/invocations
    
    Serverless: Offline [HTTP] listening on http://localhost:3000
    Serverless: Enter "rp" to replay the last request
```

Hopefully, you see this. You should be able to visit localhost:3000 and see a list of available API endpoints. If you go to /hello, things should see a dump of the APIGatewayProxyEvent we return in src/handler.ts.

```typescript
    import { APIGatewayProxyHandler } from 'aws-lambda';
    import 'source-map-support/register';
    
    export const hello: APIGatewayProxyHandler = async (event) => ({
      statusCode: 200,
      body: JSON.stringify({
        message: 'Go Serverless Webpack (Typescript) v1.0! Your function executed successfully!',
        input: event,
      }, null, 2),
    });
```

## Serverless Config

Now that we have a working API Gateway endpoint, let’s configure a few more options in the Serverless Framework.

* Set up X-Ray tracing for functions

* Set some default .env variables

* Lock the version of Serverless

* Set stage and region configs with defaults

* Set up global DynamoDB plugin

* Set up automatic pruning for lambda versions (we'll retain the last 3 versions only)

```md

    service:
      name: typescript-serverless
    
    custom:
      webpack:
        webpackConfig: ./webpack.config.js
        includeModules: true
      serverless-iam-roles-per-function:
        defaultInherit: true *# Each function will inherit the service level roles too.
      globalTables:
        regions: # list of regions in which you want to set up global tables
          - us-east-2 # Ohio (default region to date for stack)
          - ap-southeast-2 # Sydney (lower latency for Australia)
        createStack: false
      prune: # automatically prune old lambda versions
        automatic: true
        number: 3
    
    plugins:
      - serverless-offline
      - serverless-webpack
      - serverless-iam-roles-per-function
      - serverless-create-global-dynamodb-table
      - serverless-prune-plugin
    
    provider:
      name: aws
      runtime: nodejs12.x
      frameworkVersion: ‘1.64.1’
      stage: ${opt:stage, 'local'}
      region: ${opt:region, 'us-east-2'}
      apiGateway:
        minimumCompressionSize: 1024 *# Enable gzip compression for responses > 1 KB
      environment:
        DEBUG: '*'
        NODE_ENV: ${self:provider.stage}
        AWS_NODEJS_CONNECTION_REUSE_ENABLED: 1
      tracing:
        lambda: true
      iamRoleStatements:
        - Effect: Allow
          Action:
            - xray:PutTraceSegments
            - xray:PutTelemetryRecords
          Resource: "*"
    
    functions:
      hello:
        handler: src/handler.hello
        events:
          - http:
              method: get
              path: hello

```

Under provider, we set a default stage and region and some global .env variables for the service. We also set up X-Ray tracing so we can easily debug our service once it’s deployed.

We also locked our version of the Serverless Framework. I’ve not done this before and had deploy pipelines break when Serverless bumps up a version and breaks one of our plugins. At the time of writing, this the version is 1.64.1.

Finally, we set the stage and region configs with some defaults of local and us-east-2. These are set as CLI arguments (optional) during deploy.

Lastly, we configured some global IAM role statements for the service. (These are the only global roles we’ll set. Everything else we’ll set at a per-function level).

**Note**: You’ll want to comment out the global tables for your initial multi-region deploy. This plugin may not work as you expect. The reason this may fail a deploy is outlined [here](https://github.com/rrahul963/serverless-create-global-dynamodb-table/issues/17).

## Module Aliasing

The last thing to configure is module aliasing. It really blows my mind people are building Node apps in 2020 without using module aliasing. Relative import paths are too fragile for me, so let’s set up some aliases.

We are going to set three defaults (src, test, and queries) just so someone can come in and know how to set them up in the future. We’ll also use an import from queries in our example handler to make sure TypeScript compiles and resolves correctly.

Now this is a bit messy, but let’s go set this up. It’s worth the effort.

First, let webpack know about module aliases and updating the resolve object.
```typescript
    resolve: {
      extensions: ['.mjs', '.json', '.ts'],
      symlinks: false,
      cacheWithContext: false,
      alias: {
        '@src': path.resolve(__dirname, './src'),
        '@queries': path.resolve(__dirname, './queries'),
        '@tests': path.resolve(__dirname, './tests'),
      },
    },
```

Next, we’ll let our .tsconfig know about the module aliasing by updating the compilerOptions path (we can also refer to the tsconfig gist earlier).

```json
    "paths": {
      "@src/*": ["src/*"],
      "@queries/*": ["queries/*"],
      "@tests/*": ["tests/*"]
    }
```

Lastly, we’ll let ESLint know about it so we don’t get pesky linting errors when we alias. (Again, this was done in the earlier gist if you just copied that.)

```json
    "settings": {
      "import/resolver": {
        "alias": {
          "map": [
            ["@src", "./src"],
            ["@tests", "./tests"],
            ["@queries", "./queries"]
          ],
          "extensions": [
            ".ts",
            ".js"
          ]
        }
      }
    }
```

OK, time to make sure this is configured correctly.

Lets go create a /queries directory and add queries/exampleQuery.ts to validate our aliasing. We’ll make this module as simple as can be to test the compilation still works.

```typescript
export const echo = (sound: string): string => sound;
```

We’ll just take a parameter and return it straight back. We’ll get a compile time error if this doesn’t work.

Now in src/handler.ts, lets import this module with the alias we set up and try to use this in our response. Let’s update the message in our response.

```typescript
import { APIGatewayProxyHandler } from ‘aws-lambda';
import { echo } from ‘@queries/exampleQuery';
import 'source-map-support/register’;

export const hello: APIGatewayProxyHandler = async (event) => ({
  statusCode: 200,
  body: JSON.stringify({
    message: echo(‘Module aliasing is really the best’),
    input: event,
  }, null, 2),
```

Using the aliasing makes refactoring so much simpler. Your IDE should also be smart enough to autoimport with aliases (WebStorm is anyway).

And that’s about all there is to it. You should be good to start writing code and build out your services with all the goodness of TypeScript, ESLint, and Jest. I’ll cover how to use some of the powertools and how to set up SQS, SNS, Kinesis, and DynamoDB in a future post.

You can find this entire starter template on [my GitHub](https://github.com/mtimbs/typescript-serverless).

For information on how to deploy this project to your AWS account by configuring IAM roles, [read here](https://medium.com/@Michael_Timbs/creating-a-serverless-deploy-user-with-aws-iam-b2053227534).
