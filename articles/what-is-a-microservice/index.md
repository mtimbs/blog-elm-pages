---
{
    "title": "What is a MicroService?",
    "description": "Would modular architecture by any other name be just as lucrative?",
    "image": "v1703937112/what_is_microservice_yxauql.jpg",
    "published": "2023-12-30",
}
---

Firstly, I would like to beging by defining what a microservice is not.

## Microservices =/= Deployment Topology
There is a common interpretation of the word service, which understands the phrase "creating a new service" to mean creating a new deployment artefact.

This interpretation is ~~wrong~~ not very useful.

I would like for us to get out of the habit of talking about the deployment topology of our code as "services". To explain why, I will progressively change an app's deployment topology and ask at what point it becomes a "microservice". 

---

### The base case: A single monolithic application on a single server
![A single monolithic application on a single server](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/ms-1.svg)

Not much to say here. This is just our starting point.

**Verdict: Not Microservices**

---

### Scaling out behind a load balancer
![Scaling behind a load balancer](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/ms-2.svg)

The first change to our deployment topology has allowed us to scale. We've taken a single deployment artefact, and deployed it multiple times. A load balancer in front allows us to distribute incoming traffic across the apps in order to let them all contribute to serving base load traffic.

**Verdict: Not Microservices**

---

### Allow some asynchronous processing
![llow some asynchronous processing](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/ms-3.svg)

While keeping a single deployment artefact (e.g. Docker image) we have deployed a new instance. This time not behind the load balancer. This artefact is not going to serve web traffic. Instead, it is going to process messages off a queue asynchronously.

Previously this work could have been done on the web servers themselves. The queue could have already existed - it's irrelevant to the point being made. Here we've just taken the same bit of code (our monolithic application artefact) - with two different entry-points - and isolated one of the instances from incoming web traffic.  This allows us to scale our web server independently from the code we process asynchronously.

**Verdict: Not Microservices**

---

### Use a bundler/tree-shaker to remove unused code
![Use a bundler/tree-shaker to remove unused code](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/ms-4.svg)

The only change we have made in this next step is that instead of using a single build image for the two different use cases, we're using some form of build tooling/bundler to strip out dead code for each of the two entry points. Webpack or Esbuild are examples of this in the JavaScript ecosystem.

We still build both these artefacts from a single code-base, however they are distinct artefacts now. They only contain the source code required to perform their desired function.

**Verdict: Not Microservices**

---

### Move some more logic out
![Move some more logic out](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/ms-5.svg)

Assuming we were doing some event driven work, We can pull that out to its own server so that our web servers can do nothing but serve web traffic (request/response lifecycle only). This has allowed us to scale in a more predictable way behind the load balancer.

Fundamentally this is the same thing we did with the queue processor. We now just have two different things doing asynchronous work. There are now three distinct deployment artefacts that can scale and deploy independently.

**Verdict: Not Microservices**

---

### Breaking up our web server
![Breaking up our web server](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/ms-6.svg)

Here we've changed up our deployment topology again. We had some specific endpoints on our web server that were very resource hungry and/or slow. This was causing some issues with the load balancing strategies. In order to help scale, we've pulled it out to its own set of web servers (possibly behind its own load balancer). We can put an API Gateway in front of the load balancer or simply use a different domain to route traffic to the new web server. Some teams will even opt to move this to a serverless function.

It is important to note that we are still building from a single code-base, but now creating 4 different artefacts and allowing them all to scale independently. They all rely on the same underlying source code, data models, programming languages etc.

Tools like [NX](https://nx.dev/) can help you do this easily. Each of these artefacts would be a different NX application, and they could all use the same underlying libraries. NX will even help you build and deploy only the apps that have changed! Still doesn't make what we have here a MicroService architecture!

An example of this kind of workload is PDF generation. Generating PDFs from HTML is a slow and resource intensive task, often requiring very beefy system dependencies. By pulling this out to it's own dedicated server we can reduce the overall size of the Monolithic app and pull out one of the most disproportionately resource hungry tasks that can cause havoc with our load balancing strategies. 

**Verdict: Not Microservices**

---

### Welcome to Serverless architecture
![Welcome to Serverless architecture](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/ms-7.svg)

If you carry on this decomposition of your application for each possible entrypoint, you arrive at Serverless architecture. Not only is each route of our webserver now its on code artefact, we can create independent artefacts for a single http verb on a single route (e.g POST /foo, GET /foo, GET /foo/id, PATCH /foo/id etc can all be different lambdas). Even our queue/event processors can be split into multiple lambdas depending on the message type.

I've built applications like this for years and it's a really great way to scale applications. The important thing to note here is that lambdas do not call each other! Each lambda is its own complete piece of code so that it can execute it's entire job within a single process. If two lambdas rely on the same piece of code then they both bundle up that piece of code (from the shared source) and use it.

**Verdict: Not Microservices** but If you feel like we've crossed a line into MicroService architecture at this step (or even earlier) then read on.

---

### You've probably done this before without realising it
![Frontend Code Splitting](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/ms-8.svg)

Fundamentally, splitting up our server into multiple build artefacts with a tool like Webpack or esbuild is no different than what we already do on the frontend without a second thought.

Nobody would seriously try to claim that this is micro-frontends. It's simply a build time / chunking optimisation to help runtime performance. It is no different on the backend. So long as we are building from a unified source, we have done nothing more than build-time/deployment optimisation.

[//]: # (Remove all the stuff that references the Amazon architecture and talk about that with the Amazon example below)
## Still not convinced?

Some of you may still not be convinced that the definition of a MicroService I am proposing is more useful. If you had to choose between the brilliant (I mean this non-sarcastically) engineers at Amazon, or some random on the internet, I could not fault you for taking their side. If you would just humour me a little longer perhaps I can still convince you.

When you define MicroServices like Amazon did - the process of splitting bits of code into dedicated processes (that may communicate via a common protocol such as HTTP) - you not only don't really convey any meaningful information, you also imply and encourage some truly terrible things. Could you imagine taking a piece of code - any piece of code - and wherever you have a function/method call, throwing a network request in between? Even if this code was still deployed on a single VM, in a single build artefact, it would be complete insanity to do this! The added failure scenarios, load, performance cost would make it just about the most irresponsible thing you could do.

I would urge you to consider some of the MicroService design principles or selling points and how they would apply to any of those scenarios.

**Could we use multiple languages?**

The core part of my examples earlier was that we could have built a single deployment artefact from a singe code base and still had the benefits of the scale from the distributed deployment topology. Using tree-shaking was just a performance benefit and something that a lot of languages allow (not just javascript). In order to do this we need to be able to re-use code across multiple entry-points. This requires that the entire code base be in the same language (ignoring languages that can wrap/call other languages as that is besides the point)

In order to use different languages you'd lose the ability to share code across those artefacts. If two of the deployment artefacts (aka entry-points) relied on a core bit of functionality you wouldn't be able to just consume it directly. You would need to add some kind of communication protocol in between. This is **100% pure overhead** as discovered by the Amazon team. Not only is this a performance overhead but you now need to write, maintain and test a bunch of glue code for handling that communication layer.

**Can we do independent builds?**

If you look at the examples Every single on of those artefacts would have needed to be rebuilt on every deploy. They could have been deployed independently but they need to be built (or at least analyzes) each time we release to see if anything has changed that requires a new deployment. Even NX still in some respect "builds" everything - in the sense that a build even makes sense for a scripting language like JS.

If we want to consider the case of where disparate bits of code communicate via some standard protocol (e.g. HTTP) again, we could then - in theory do independent builds. Again you pay a steep price for communication in this model.

**Each "service" (artefact) should have its own database?**
That would be a truly ridiculous notion in any of those examples. Imagine you had one artefact persisting a model, and another reading it. How could they ever "have their own database"? I have spoken to people who have actually attempted this via database replication. They've used tools like Kafka to sync databases across their "services". Database replication is not the same thing as "having your own database". Even in the AWS case they used a shared database (S3) across each of their "services"


[//]: # (Introduce a change where differnt functions call each other instead of bundling by entrypoint. This is a good segway to Amazon Prime example)

## The infamous Amazon Prime blog post
![Amazon Prime Blog Post Heading](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/amazonprimeheading.png)

Earlier in 2023 Amazon Prime released a blog post claiming that they reduced their costs by 90% by abandoning microservices and going back to a monolith. A lot of anti-microservice people jumped on this, and it made a lot of noise on Twitter.

The problem with this claim is that it is nonsense. The very title of the article exposes the lie. The audio/video monitoring **SERVICE**. Of course Amazon Prime is still built with a microservice architecture. They just changed the deployment topology of the **audio/video monitoring SERVICE**. They went from a distributed architecture (withing the **service** boundary) to a monolithic, single process, architecture.

Some quotes from the [article](https://www.primevideotech.com/video-streaming/scaling-up-the-prime-video-audio-video-monitoring-service-and-reducing-costs-by-90) that highlight that they are still in fact using MicroServices.

> Our Video Quality Analysis (VQA) team at Prime Video

The fact that they have dedicated teams responsible for different parts of the domain is a good clue that they still have MicroServices

> The initial version of our service consisted of distributed components that were orchestrated by AWS Step Functions. The two most expensive operations in terms of cost were the orchestration workflow and when data passed between distributed components. To address this, we moved all components into a single process to keep the data transfer within the process memory, which also simplified the orchestration logic.

They literally call it a service again here. All they really did was move from distributed architecture to a monolithic one - **within the (micro)service boundary!**


>  Could you imagine taking a piece of code - any piece of code - and wherever you have a function/method call, throwing a network request in between? Even if this code was still deployed on a single VM, in a single build artefact, it would be complete insanity to do this! The added failure scenarios, load, performance cost would make it just about the most irresponsible thing you could do.


## Ok fine, then what are MicroServices?

MicroServices are all about the **logical separation of your domain**. We can't tell anything about what each service constitutes by simply looking at the overall deployment topology of the business. One service may be a single monolithic app, another may be the case of a monolithic app image but behind a load balancer, and another may be fully blown serverless architecture. It really doesn't matter. They could all also be single monoliths all deployed on the same server.

![Example Microservices](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/ms-9.svg)

What makes something a MicroService is that it is built and deployed from independent source code (e.g. it's own Git repository - although tooling like NX also makes it possible to have independent source code boundaries within a single Git repo.)

When done right, MicroServices are responsible for different parts of the business domain and can almost be treated like standalone products. In this scenario a single service is owned by a single team. If we consider a product like Amazon Prime, there are a heap of different business capabilities that are required to make that product successful. Video and Audio monitoring is one example of those capabilities.

[Udi Dahan](https://udidahan.com/) defines MicroServices as "the technical authority for a business capability" and I personally quite like this definition - although I think it can also be a bit ambiguous and still lead to bad service boundaries (an example of which I will provide in a follow-up post).

Personally, I don't think I have settled on my own perfect definition of a MicroService. I think for now, I would think that if you used the words MicroService and [Bounded Context](https://martinfowler.com/bliki/BoundedContext.html) interchangeably you'd find that your life improved a lot. Perhaps I would actually define a MicroService as "one or more bounded contexts" because I think it is perfectly fine for a MicroService to encompass more than one Bounded Context. I would not recommend splitting a Bounded Context over multiple MicroServices for reasons I will have to elaborate on in a follow-up post. This naturally leads to an (I think) novel definition of a Monolith as well:

> A monolith is a special case of MicroServices, where the number of services is equal to one.

If I take my definition of a MicroService seriously, it raises a fairly obvious question....

**If a MicroService is the equivalent of a Bounded Context, does that mean that you can only do MicroServices if you are doing [DDD](https://martinfowler.com/bliki/DomainDrivenDesign.html)?**

Surprisingly, my intuition is to say **yes**. 

So what about the people that are **not** doing DDD, but have something that _looks like_ what others might call MicroServices? Well I think I would just call that a **[Distributed Architecture](https://en.wikipedia.org/wiki/Distributed_computing)**. I think this is a more fitting description as many critics of MicroServices often cite a _[Distributed Big Ball of Mud](https://news.ycombinator.com/item?id=10328015)_ as the end state of systems built this way. It is also, in my experience, the inevitable end state of software that attempts to break their system into MicroServices without following clean service boundaries like the ones that exist between Bounded Contexts. 

The other problem that exists with saying that MicroServices === Bounded Contexts is that it is possible to do DDD with a Monolith (many such cases). While I have cheekily defined a monolith as the special case of MicroServices where N=1, and also said that a MicroService is _one or more_ Bounded Contexts, I think we can further refine the definition statement to be more precise. Perhaps:

> A MicroServices is the hard separation of Bounded Contexts within a Domain

Each Bounded Context is then owned by it's own team (and only one team), and has its own code base* (this doesn't mean you cant do MicroServices with mono-repos, just that there needs to be a hard separation between them inside the mono-repo).

## MicroServices are about scaling teams, not compute

If each microservice is a hard separation of a Bounded Context, it is in essence a standalone product. You could then, to some extent, treat them just like mini-companies. Each service has its own product manager, development team(s), designers, infrastructure layers/management etc.

These services could all live in a single Git repository, or multiple. It doesn't matter - although I would default to one repo per service because in most cases very little is gained by co-location unless you are a megacorp that could not physically track all its IP assets without a monorepo.


![Bonsai Quote](https://s3.ap-southeast-2.amazonaws.com/images.michaeltimbs.me/Bonsai.png)
> The object is not to make the product look like microservices, but to make the microservice look like a product
