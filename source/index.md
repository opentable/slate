---
title: OpenTable Developer's Guide

language_tabs:
  - ruby
  - python
  - shell
  
toc_footers:
  - <a href='#'>Sign Up for a Developer Key</a>
  
includes:
  - errors

search: true
---

# Welcome

Welcome to the [OpenTable's](http://wwww.opentable.com) Online Developer's Guide. This guide is will show you how to integrate with OpenTable's APIs to manage your restaurants, reservations, and inventory. 



# Development Basics


### SECURITY

> Include the authentication token issued to you using the HTTP Authorization header

OpenTable's Network Partner APIs can only be accessed via **HTTPS**. This applies to all of the environments; integration, pre-production, and producton.

OpenTable uses ouath 2.0 as the primary security mechanism.This means that a token must be obtained at the stat of a session and used in all subsequent calls. Tokens should be presented to the API server by use of the **Authorization** header.

### CONTENT NEGOTIATION

Data is sent and received in JSON format unless otherwise specified in this documentation. Clients should specify **application/json** as the preferred **Content-Type** in all requests to the server.


### COMPRESSION

OpenTable's Partner Network APIs support LZ4 encoding. Client application should specify **lz4** via the **Content-Encoding** HTTP header whenever possible.

<aside class="notice">
Compression will dramatically improve the performance of your applications and should be implemented by your partner server implemntation as well as your client implementation. In short, your partner system should be able to send and respond with lz4 compressed content whenever possible.
</aside>

## Payloads and Protocols
### oauth 2.0
### json 
### Compression
### UNIQUE REQUEST IDS

##Setup
###Callbacks 
###ERROR CODES AND HANDLING


# Environments

OpenTable has three separate environments. Each environment:

* corresponds to a different stage of the devlopment process
* has different DNS names for the core services
* has it's own copy of the data. State is not shared across environments.


## Continuous Integration
The Continuos Integrtation **(CI)** environment is used for daily automated build and test. Run your builds and tests against CI as frequently as needed to validate new functionality. Beta buids should always pass through the CI environment


Service Name | Service URL
--------- | -----------
Authentication | https://oauth-ci.opentable.com
Channels | https://channels-ci.opentable.com


## Pre-Production
The Pre-Production **(PP)** environment is available once you are ready for final acceptance testing of your OpenTable integrations. Load testing can also be scheduled and performed in thisenvironment.

Service Name | Service URL
--------- | -----------
Authentication | https://oauth-pp.opentable.com
Channels | https://channels-pp.opentable.com


## Production
The production services are the same one's accessed by the OpenTable.com web site. Your integration is live once it is communicating with the OpenTable production web services.

Service Name | Service URL
--------- | -----------
Authentication | https://oauth.opentable.com
Channels | https://channels.opentable.com

<aside class="warning">Devloper keys must be specifically granted production access. Please cnontact us to request production privileges for your developer key.</aside>


# Booking

##reservation
The partner data store is considered the source of truth for reservation information. Reservations cannot be created, changed, or canceld without first be ing communicated to the partner's api endopoints. OpenTable will always sek to make a reservation with a lock id specified. The lockid may refer to an ephemeral lock that has been discarded. In these cases OpenTable expects the partner api to attempt to book the reservation an a 'best efforts' basis as the uderlying inventory may have been taken by another diner.


###ENTITY
Member | Description
--------- | -----------
rid | The rid that this reervation is assigned to
href | The href that can be used to retrieve the reservation details from OpenTable
lock_id | **Optional.** The id of the inventory lock acquired for this reservation.
res_id | The id of the reservation. *This will be empty on creation and must be provided by the partner*
res_datetime | The GMT time for which the reservation was maded
res_state | This value must be One of the OpenTable RESERVATION STATES *(see below)*. The default state for a new reservation is BOOKED.
party_size | The party size of the reservation
diner_name | The first and last name of the diner
diner_phone | **Optional.** The phone number for the diner for this reservation
diner_email | **Optional.** The email address of the diner. This field will only be present if the diner has opted into email marketing for OpenTable.
diner_notes | **Optional.**  Notes submitted by the diner along with this reservation
diner_tags | **Optional.** Array of OpenTable specific diner tags


###RESERVATION STATES

Reservations will always be in one of the following states.

NAME | Description
--------- | -----------
BOOKED | The reservation has been made. All reservations must start off in this state.
SEATED | The party has arrived at the restaurant and ben seated.
ASSUMED_SEATED | Time for reservation has passed but reservation has not placed into one of the terminal states by the partner system (DONE, NOSHOW, CANCELED). *OpenTable will set reservations to this state as part of its daily shift maintenance.*
DONE | The reservation has been marked as 'Done' by the in-house staff
NOSHOW | The diner failed to show at the restaurant
CANCELED | The reservation has been canceled

## Making a new reservation

OpenTable will call the partner API whenever a diner is attempting to book a reservation. OpenTable will call the **lock** API prior to booking a reservation via a POST to the reservation entity. 

Other points of note:

* The href fiedld in the reservation supplied by OpenTable when booking the reservation will remain valid only if OpenTable receives a valid response to its POST call to the reservation endpoint.
* The res_id field MUST be populated and returned by the partner API if the reservation is created in the partner's reservation system.
* Should there be a communication break prior ro OpenTable receiving a 201 (or other) response then OpenTable will attempt at least one retry to create the reservation. The retry attempt will have the same unique href as was specified in the first attempt at reservation creation.


###URL DETAIL

`http://<partner_callback_url>/reservation/<reservation_id>`


## Receiving updates

OpenTable will PUT a reservation update message should any of the following reservation fields change.

* Party Size
* Reservation date and/or time

Providers should acknowledge the PUT with a 200 and update the sequence-id with a neew value in order to help protect against collisions. 

###URL DETAIL

`http://<partner_callback_url>/reservation/<reservation_id>`

###ENTITY

see **Reservations** section above

<aside class="warning">Reservations cannot be moved across restaurants or systems. In order to move a reservation it must first be cancelled and then a new one made in the target restaurant.</aside>

## Sending Notifications

Partner systems should perform a PUT to the OpenTable reservation system should any of the following reservation fields change.

* Party Size
* Reservation date and/or time


###URL DETAIL

`OpenTable href for the reservation. Please see reservation schema.`



# Inventory

OpenTable offers partner's the ability to express availability using a **capacity-based model**. In this model the partner informs OpenTable of the availability for a given shift and date using a range of times, pacing, and party sizes that can be accomodated.


## setup

>Partner POST :: http://np.opentable.com/setup/8675309

```json
  {
    "rid": "8675309",
    "availability": "capacity",
    "online": "true"
  }
```
> OpenTable resopnse :: HTTP 1.1 200 OK

```json
  {
    "rid": "8675309",
    "availability": "capacity",
    "online": "true",
    "timestamp": "87191021283"
  }
```


The setup entity is used to specify how the restaurant will integrate with OpenTable. This entry must be POST'd to the server prior to the partner sending any capacity or slot updates. Availability updates sent prior to the setup being POST'd will faile with an error code of 407 (unexpected).

###URI

`http://np.opentable.com/<partner_id>/setup/<rid>`


###ENTITY FIELDS


Member | Description
--------- | -----------
rid | The restaurant id. Not required
availability | Must be set to either 'capacity' or 'slot'
online | If set to 'true', the restaurant will appear on the OpenTable website


## capacity

The capacity entity is used by parteners to communicate the availability they are offering OpenTable diners for booking. OpenTable will attempt to consume this capcity until none is left. Partners are free to re-publish their capcaity as often as needed to either increase or decrease the allocation of inventory to OpenTable. The capacity document may contain more than one shift for the day; however shifts may not overlap in time.

###ENTITY


Member | Description
--------- | -----------
rid | The restaurant id. Not required
range_start | GMT date and time of the time period
range_end | GMT date and time of the time period
max_covers | The maximum number of web reservations the partner wishes to receive during this time range
min_party_size | The minimum party size that will be accpted for booking
max_party_size | The maximum party size that will be accpted for booking
pacing | The number of reservations that will be accepted at each 15 minute pacing interval



## lock

> OpenTable HTTP Request

```json
POST

  {
    "rid": 1,
    "date": "Fluffums",
    "covers": "calico",
    "expirationSeconds": 180,
    "turnTimeMinutes": 90
  }
```

> Partner Response

```shell
Location: "https://<partner_api>/lock/0a192810120212"
```
```json
  {
    "lock_id": "a192810120212", //assigned_by_partner
    "rid": 1,
    "date": "Fluffums",
    "covers": "calico",
    "expirationSeconds": 180,
    "turnTimeMinutes": 90
  }
```

This endpoint is called to reserve inventory while the diner completes the reservation process. The channel inventory system must hold the invetory booking until the expiration date is reached. If the expiration date is reached and the lock has not been cancelled then the underlying inventory can be released and used for other reservations.

### HTTP Request

`INBOUND POST http://<your_endpoint>/lock`

### ENTITY

Parameter | Required | Description
--------- | ------- | -----------
rid | Yes | The restaurant id
lock_id | Yes | The id of the lock. This is assigned by the partner system and **must be globally unique**.
date | Yes | The GMT start date and time of the reservation
covers | Yes | The size of the party the booking is for
expirationDate | No | GMT time at which the lock expires
turnTime | No | The length of time the reservation will be made for. This vakue is given in minutes.


<aside class="success">
Remember — always use your developer key
</aside>
