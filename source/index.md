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

Welcome to the [OpenTable](http://wwww.opentable.com) Developer's Guide. This site will show you how to integrate with OpenTable's APIs to manage your restaurants and their inventory. 


# Authentication

> To authorize, use this code:

```ruby
require 'kittn'

api = Kittn::APIClient.authorize!('meowmeowmeow')
```

```python
import kittn

api = kittn.authorize('meowmeowmeow')
```

```shell
# With shell, you can just pass the correct header with each request
curl "api_endpoint_here"
  -H "Authorization: meowmeowmeow"
```

> Make sure to replace `meowmeowmeow` with your API key.

Our REST-based APIs are accessible over HTTPs using JSON payloads. You must have a developer key to access the APIs. You can apply for a new Developer Access Key by contacting us [here](mailto:devkey-request@opentable.com).

OpenTable uses oauth2.0 and expects for the API key to be included in all API requests to the server in a header that looks like the following:

`Authorization: devkey-123`

<aside class="notice">
You must replace `devkey-123` with your personal API key.
</aside>


# Development Basics

## Payloads and Protocols
### oauth 2.0
### json 
### Compression
### Sequence Identifiers

##Setp
###Callbacks 
###ERROR CODES AND HANDLING


# Environments

OpenTable has three separate environments. Each environment:

* corresponds to a different stage of the devlopment process
* has different DNS names for the core services
* has it's own copy of the data. state is not shared across environments.


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

OpeTanbe will call the partner API whenever a diner is attempting to book a reservation. OpenTable may additionally call the **lock** API prior to booking a reservation. The call to lock will only occur when attempting to book a restaurant that has been marked as using the slot availability mode. Capacity mode bookings do not require slot locks by the partner system.

Here are some other important points to note:

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

OpenTable offers two models for API integrations; the *capacity-based model* and the *slot-based model*. The capacity based model is the simpler of the two and offers developers coarse grained control of the availability that surfaces on **www.opentable.com**.

The slot-based model offer extremely fine-grained control and is more complex to implement The slot-based model also involves much more frequent network communication between the OpenTable services and the partners providing inventory.

The slot-based model has the advantage of allowing partners to control the inbound flow of reservations in near-real time.

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

Partners support the capacity-based model by publishing their capcity which details the number of bookings that they are willing to take along with the period of time for which they are willing to be taken. 

Partners can override the capacity for a given day by simply publishing a new capacity document for that day. The capacity document may contain more than one shift for the day. However shifts may not overlap in time.

###ENTITY


Member | Description
--------- | -----------
rid | The restaurant id. Not required
range_start | GMT date and time of the time period
range_end | GMT date and time of the time period
max_covers | The maximum number of web reservations the partner whiches to receive during this time range
min_party_size | The minimum party size that will be accpted for booking
max_party_size | The maximum party size that will be accpted for booking
pacing | The number of reservations that will be accepted at each 15 minute pacing interval


## slot

OpenTable supports fine-grained integrations with partners via the publishing of **slot-based** availability. The slot-based model allows for restaurants to specify the seating opportunities available for specified party sizes. Unlike capacity based inventory, the partner must update the slot model every time availability is changed. This may happend for a number of seating events; new reservations, cancellations, or even moving reservations to different tables within the restaurant.

###URL DETAIL

`http://np.opentable.com/<partner_id>/slot/<rid>`

Parameter | Required | Default | Description
--------- | ------- | --------| ---
sequence_id | Yes | - | The current partner sequnce id for this restaurant. This value should be incrmented by one with each new send.


###ENTITY
Member | Description
--------- | -----------
rid | The restaurant id. Not required
time | The time increment referred to in GMT. Must be on 15 minute interval; e.g. 7:00, 7:15, 7:30, and 7:45
party_size | The party size that may occupy this slot
count | The number of slots for this party size and this time that remain
shift_date | The business day that corresponds to this shift. This will be overwritten by the OpenTable api server based on the restaurant setup.

<aside class="warning">The API will consider any time slot that has not been published to have a count of zero; meaning these time intervals will be unavailble for booking on the web. Once a slot has ben publish for a given time and party size, publishers must republish the same slot with a count of '0' in order ro make the slot unavailable on the website.</aside>

## cache

The cache is the entity that represents OpenTable's cached data for a given restaurant. Partners can call DELETE to invalidate OpenTable's cache. This will cause OpenTable to re-request all of the restaurant's availability for the standard time windoww of 100 days.

Partners may also perform a GET on the cache in order to validate OpenTable's current cache status.

Partners may trigger a cache reset by POSTing a cache entity with a last_sequence_id of 0. OpenTable may invalidate the partner's cache by PUTing a cache entity with a last_sequence_id of 0. When a partner system receives a messag with a last_sequence_id the partner should send availability for the next 100 days.

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
    "lockId": "a192810120212", //assigned_by_partner
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
date | Yes | The GMT start date and time of the reservation
covers | Yes | The size of the party the booking is for
expirationDate | No | GMT time at which the lock expires
turnTime | No | The length of time the reservation will be made for. This vakue is given in minutes.


<aside class="success">
Remember — always use your developer key
</aside>
