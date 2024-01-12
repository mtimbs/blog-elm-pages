---
{
    "title": "Microservices have nothing to do with deployment topology",
    "description": "Too many people use the terms Microservice to refer to an independently deployed piece of code. This is not a good definition of a Microservice. Microservice architecture has nothing to do with deployment topology",
    "image": "v1703937112/what_is_microservice_yxauql.jpg",
    "published": "2023-12-30",
}
---

There is a common interpretation of the word service, which understands the phrase "creating a new service" to mean creating a new deployment artefact.

This interpretation is ~~wrong~~ not very useful.

I would like for us to get out of the habit of talking about the deployment topology of our code as "services". To explain why, I will progressively change an app's deployment topology and ask at what point it becomes a "microservice". Our base case is going to be a single monolithic application deployed on a single VM.

### Scaling out behind a load balancer
![Scaling behind a load balancer](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/ms-2.svg)

The first change to our deployment topology has allowed us to scale. We've taken a single deployment artefact, and deployed it multiple times. A load balancer in front allows us to distribute incoming traffic across the apps in order to let them all contribute to serving base load traffic.

**Verdict: Not Microservices**


### Allow some asynchronous processing
![llow some asynchronous processing](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/ms-3.svg)

While keeping a single deployment artefact (e.g. Docker image) we have deployed a new instance. This time not behind the load balancer. This artefact is not going to serve web traffic. Instead, it is going to process messages off a queue asynchronously.

Previously this work could have been done on the web servers themselves. The queue could have already existed - it's irrelevant to the point being made. Here we've just taken the same bit of code (our monolithic application artefact) - with two different entry-points - and isolated one of the instances from incoming web traffic.  This allows us to scale our web server independently from the code we process asynchronously.

**Verdict: Not Microservices**


### Use a bundler/tree-shaker to remove unused code
![Use a bundler/tree-shaker to remove unused code](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/ms-4.svg)

The only change we have made in this next step is that instead of using a single build image for the two different use cases, we're using some form of build tooling/bundler to strip out dead code for each of the two entry points. Webpack or Esbuild are examples of this in the JavaScript ecosystem.

We still build both these artefacts from a single code-base, however they are distinct artefacts now. They only contain the source code required to perform their desired function.

**Verdict: Not Microservices**


### Move some more logic out
![Move some more logic out](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/ms-5.svg)

Assuming we were doing some event driven work, We can pull that out to its own server so that our web servers can do nothing but serve web traffic (request/response lifecycle only). This has allowed us to scale in a more predictable way behind the load balancer.

Fundamentally this is the same thing we did with the queue processor. We now just have two different things doing asynchronous work. There are now three distinct deployment artefacts that can scale and deploy independently.

**Verdict: Not Microservices**


### Breaking up our web server
![Breaking up our web server](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/ms-6.svg)

Here we've changed up our deployment topology again. We had some specific endpoints on our web server that were very resource hungry and/or slow. This was causing some issues with the load balancing strategies. In order to help scale, we've pulled it out to its own set of web servers (possibly behind its own load balancer). We can put an API Gateway in front of the load balancer or simply use a different domain to route traffic to the new web server. Some teams will even opt to move this to a serverless function.

It is important to note that we are still building from a single code-base, but now creating 4 different artefacts and allowing them all to scale independently. They all rely on the same underlying source code, data models, programming languages etc.

Tools like [NX](https://nx.dev/) can help you do this easily. Each of these artefacts would be a different NX application, and they could all use the same underlying libraries. NX will even help you build and deploy only the apps that have changed! Still doesn't make what we have here a MicroService architecture!

An example of this kind of workload is PDF generation. Generating PDFs from HTML is a slow and resource intensive task, often requiring very beefy system dependencies. By pulling this out to it's own dedicated server we can reduce the overall size of the Monolithic app and pull out one of the most disproportionately resource hungry tasks that can cause havoc with our load balancing strategies. 

**Verdict: Not Microservices**


### Welcome to Serverless architecture
![Welcome to Serverless architecture](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/ms-7.svg)

If you carry on this decomposition of your application for each possible entrypoint, you arrive at Serverless architecture. Not only is each route of our application now its own code artefact, we can create independent artefacts for a single http verb on a single route (e.g POST /foo, GET /foo, GET /foo/id, PATCH /foo/id etc can all be different lambdas). Even our queue/event processors can be split into multiple lambdas depending on the message type.

I've built applications like this for years and it's a really great way to scale applications. The important thing to note here is that lambdas do not call each other! Each lambda is its own complete piece of code so that it can execute it's entire job within a single process. If two lambdas rely on the same piece of code then they both bundle up that piece of code (from the shared source) and use it.

You've probably done this before without realising it:

![Frontend Code Splitting](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/ms-8.svg)

Fundamentally, splitting up our server into multiple build artefacts with a tool like Webpack or esbuild is no different than what we already do on the frontend.

Nobody would seriously try to claim that this is micro-frontends. It's simply a build time / chunking optimisation to help runtime performance. It is no different on the backend. So long as we are building from a unified source, we have done nothing more than build-time/deployment optimisation.

**Verdict: Not Microservices**


## The infamous Amazon Prime blog post
![Amazon Prime Blog Post Heading](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/amazonprimeheading.png)

Earlier in 2023 Amazon Prime released a blog post claiming that they reduced their costs by 90% by abandoning microservices and going back to a monolith. A lot of anti-microservice people jumped on this, and it made a lot of noise on Twitter.

The problem with this claim is that it is nonsense. The very title of the article exposes the lie. The audio/video monitoring **SERVICE**. Of course Amazon Prime is still built with a microservice architecture. They just changed the deployment topology of the **audio/video monitoring SERVICE**. They went from a distributed architecture (within the **service** boundary) to a monolithic, single process, architecture.

Some quotes from the [article](https://www.primevideotech.com/video-streaming/scaling-up-the-prime-video-audio-video-monitoring-service-and-reducing-costs-by-90) that highlight that they are still in fact using MicroServices.

> Our Video Quality Analysis (VQA) team at Prime Video

The fact that they have dedicated teams responsible for different parts of the domain is a good clue that they still have MicroServices

> The initial version of our service consisted of distributed components that were orchestrated by AWS Step Functions. The two most expensive operations in terms of cost were the orchestration workflow and when data passed between distributed components. To address this, we moved all components into a single process to keep the data transfer within the process memory, which also simplified the orchestration logic.

They literally call it a service again here. All they really did was move from distributed architecture to a monolithic one - **within the (micro)service boundary!**


Could you imagine taking a piece of code - any piece of code - and wherever you have a function/method call, throwing a network request in between? Even if this code was still deployed on a single VM, in a single build artefact, it would be complete insanity to do this! The added failure scenarios, load, performance cost would make it just about the most irresponsible thing you could do.


