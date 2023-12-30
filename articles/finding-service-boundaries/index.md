---
{
"title": "Finding (micro)service boundaries",
"description": "Where to draw the boundaries in your microservice architecture",
"image": "v1629197720/service-boundaries-header_mjc1t5.jpg",
"published": "2023-06-28",
}
---

I've been on the (micro)services journey a few times now and I have seen it pan out in many ways. Over time, I have found what I believe to be the most helpful way to break down a significantly large piece of software into (micro)services. I have refactored existing (micro)service boundaries to align with these principles, and have reaped the rewards that they offer. I have also had the rare opportunity to work at an organisation that had half the product organised along these principles and half the organisation following what I think of as the *default* (micro)service architecture. This has allowed me to get a direct comparison between the performance of teams within the same domain, on a mature - enterprise scale - product, who draw service boundaries very differently.

## The "default" Microservice architecture

Based on my own experience, anecdotes from other developers, and discussions when hiring, most companies approach microservices with very little upfront planning or thought. Typically, they start carving up their software into microservices based on one or more of these criteria:

- Whatever feature(s) happen to be next on the roadmap - each new feature gets its own new service.
- Break each "entity" out into its own microservice.  
- Give each development "team" or "squad" its own service to manage
- Create services roughly matching the organisational structure
- Arbitrary pieces of functionality are broken out into "microservices" in an attempt to isolate as much code as possible

All of these approaches have significant downside and cost [TODO: Link to dedicated article explaining these in detail]


