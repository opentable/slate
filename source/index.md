---
title: OpenTable Developer's Guide

language_tabs:
  - ruby
  - python
  - shell
  
toc_footers:
  - <a href='#authorization'>Sign Up for Developer Access</a>
  
includes:
  - errors

search: true
---

# Welcome

Welcome to the [OpenTable](http://www.opentable.com) Developer's Guide. This guide is will show you how to integrate with OpenTable's APIs to manage your restaurants, reservations, and inventory.

# Getting Started

## Overview

Integration with the OpenTable Partner API involves following steps:

1. Obtain a client id and client secret that are used for authorization.
2. Register a restaurant to provide required metadata and a callback. This will create a restaurant profile in [www.opentable.com] (www.opentable.com) search results.
3. Publish your seating availability. This will enable diners to find available tables on [www.opentable.com] (www.opentable.com).
4. Accept reservation booking requests from OpenTable.
5. Send and receive reservation updates and cancellations.

## Payloads and Protocols

### Security

OpenTable uses OAuth 2.0 as the primary authorization mechanism. This means that an access token must be obtained and submitted with all requests. See [Authorization](#authorization) section for more details.

OpenTable's Network Partner APIs can only be accessed via **HTTPS**. This applies to all environments.

### Content Negotiation

Data is sent and received in JSON format unless otherwise specified in this documentation. Clients should specify **application/json** in the **Accept** header for all requests to the server.

### Compression

OpenTable's Partner Network APIs support LZ4 encoding. Client application should specify **lz4** via the **Accept-Encoding** HTTP header whenever possible.

<aside class="notice">
Compression will dramatically improve the performance of your applications and should be implemented by your partner server implementation as well as your client implementation. In short, your partner system should be able to send and respond with lz4 compressed content whenever possible.
</aside>

### Unique Request Ids

All POST, PUT, and PATCH HTTP requests should contain a unique X-Request-Id header which is used to ensure idempotent message processing in case of a retry

## Error Codes and Handling

* TBD

# Environments

OpenTable has three separate environments. Each environment:

* corresponds to a different stage of the development process
* has different DNS names for the core services
* has it's own copy of the data. State is not shared across environments.

## Continuous Integration
The Continuous Integration **(CI)** environment is used for daily automated builds and tests. Run your builds and tests against CI as frequently as needed to validate new functionality. Beta builds should always pass through the CI environment.

Service Name | Service URL
--------- | -----------
Authentication | https://oauth-ci.opentable.com
Network Partner | https://np-ci.opentable.com

## Pre-Production
The Pre-Production **(PP)** environment is available once you are ready for final acceptance testing of your OpenTable integrations. Load testing can also be scheduled and performed in this environment.

Service Name | Service URL
--------- | -----------
Authentication | https://oauth-pp.opentable.com
Network Partner | https://np-pp.opentable.com

## Production
The production services are the same ones accessed by the OpenTable.com web site. Your integration is live once it is communicating with the OpenTable production web services.

Service Name | Service URL
--------- | -----------
Authentication | https://oauth.opentable.com
Network Partner | https://np.opentable.com

<aside class="warning">Client ids need be specifically granted production access. Please contact us to request production privileges for your client id.</aside>

# Authorization

## Requesting a Client Id

To request developer access, [send us an email](mailto:dchornyi@opentable.com). Self-registration will be available soon.

## Obtaining a Token

### Submitting Client Credentials

> GET :: http://oauth.opentable.com/api/v2/oauth/token?grant_type=client_credentials

> OpenTable response :: HTTP 1.1 200 OK

```json
    {
        "access_token": "ba4a443d-3cc2-4472-9a92-e2347f1f5cf1",
        "token_type": "bearer",
        "expires_in": 2419181,
        "scope": "DEFAULT"
    }
```

Client credentials are submitted in the `Authorization` header as defined in the [OAuth spec](https://tools.ietf.org/html/rfc6749#section-2.3).
Given a client id (e.g., "client_id") and a client secret (e.g., "client_secret"), you need to do the following:

1. Concatenate them using a ":" (e.g., "client_id:client_secret")
2. Base64 encode the result from step 1 (e.g., "Y2xpZW50X2lkOmNsaWVudF9zZWNyZXQ=")
3. Set the header "Authorization: Basic <result from step 2>" (e.g., "Authorization: Basic Y2xpZW50X2lkOmNsaWVudF9zZWNyZXQ=")

## Authorizing Requests

> Authorization: bearer ba4a443d-3cc2-4472-9a92-e2347f1f5cf1

1. [Obtain an access token](#obtaining-a-token)
2. Set the header "Authorization: bearer <result from step 1>" (e.g., "Authorization: bearer a1c7b724-0a20-42be-9dd4-23d873db1f9b")
3. Send the request
    a. If the token is valid and not expired, an appropriate response from the resource server will be returned.
    b. If the token is not valid, the resource server responds using the appropriate HTTP status code (typically, 400, 401, 403, or 405) and an error code [https://tools.ietf.org/html/rfc6750#section-3.1](https://tools.ietf.org/html/rfc6750#section-3.1)

# Registering a Restaurant

>Partner POST :: http://np.opentable.com/&lt;partner_id&gt;/restaurants/&lt;rid&gt;

```json
  {
    "online": "true",
    "callbackURL": "http://acme.com/api/restaurants/12345"
  }
```
> OpenTable resopnse :: HTTP 1.1 200 OK

```json
  {
    "rid": "8675309",
    "online": "true",
    "callbackURL": "http://acme.com/api/restaurants/12345"
  }
```

The setup entity is used to specify how the restaurant will integrate with OpenTable. This entry must be POSTed to the server prior to the partner sending any availability updates. Availability updates sent prior to the setup being POSTed will fail with an error code of 407 (unexpected).

### URI

`http://np.opentable.com/<partner_id>/restaurants/<rid>`

### Entity Fields

Member | Description
--------- | -----------
rid | The restaurant id. Not required
online | If set to 'true', the restaurant will appear on the OpenTable website
callback_url | The base url of the callback OpenTable will use to communicate with your integration
partner_oauth | The oauth service OpenTable will communicate with to obtain tokens
callback_key | The oauth key OpenTable will use to navigate the oauth handshake
callback_secret | The oauth secret OpenTable will use to navigate the oauth handshake

# Publishing Availability

## Availability

> Partner POST :: http://np.opentable.com/&lt;partner_id&gt;/availability

```json
  [
      {
      "rid" : "8675309",
      "date" : "2015-05-02",
      "party_size" : 2,
      "time" : [420, 435, 450, 465],
      "sequence_id" : 1
      } ,
      {
        "rid": "8675309",
        "date": "2015-05-02",
        "party_size" : 3,
        "time": [420, 435],
        "sequence_id" : 1
      }
  ]
```
> OpenTable response :: HTTP 1.1 200 OK
```

Partners can inform OpenTable of availability by pushing the available inventory as a list of slots; where a slot is simply a date, time, and party size that can be booked at the restaurant.

Partners may specify multiple values for the time field in order to efficiently represent many slots that apply to the same party size.

### HTTP Request

`PUT http://np.opentable.com/<partner_id>/availability`

### Entity

Member | Description
--------- | -----------
rid | The restaurant id. **Required**
date | The calendar date of the bookable slot
party_size | The size of the party that may be booked at the time(s) specified
time | An arry of times that date an party size apply to. Given as offsets in minutes from midnight.
sequence_id | The monotonically increasing message id; updated by the partner API and validated by the OpenTable API. The OpenTable services will trigger a cache refresh if messages are deemed to be missing or too far out of order. When a cache refresh is triggered the sequence id should be set to zero for both parties and the partner integration should resend all of the (100) days that will need to be re-cached by the OpenTable services. Updates within the same PUT message for the same RID should have the same sequence id. The sequence id is global across all partner restaurant ids.

# Booking a Reservation

## Reservation
The partner data store is considered the source of truth for reservation information. Reservations cannot be created, changed, or canceled without first being communicated to the partner's api endpoints. OpenTable will always sek to make a reservation with a lock id specified. The lock id may refer to an ephemeral lock that has been discarded. In these cases OpenTable expects the partner api to attempt to book the reservation an a 'best efforts' basis as the underlying inventory may have been taken by another diner.

### Entity
Member | Description
--------- | -----------
rid | The rid that this reservation is assigned to
href | The href that can be used to retrieve the reservation details from OpenTable
lock_id | **Optional.** The id of the inventory lock acquired for this reservation.
res_id | The id of the reservation. *This will be empty on creation and must be provided by the partner*
res_date | The UTC date and time for which the reservation was made
res_state | This value must be One of the OpenTable RESERVATION STATES *(see below)*. The default state for a new reservation is BOOKED.
party_size | The party size of the reservation
diner_name | The first and last name of the diner
diner_phone | **Optional.** The phone number for the diner for this reservation
diner_email | **Optional.** The email address of the diner. This field will only be present if the diner has opted into email marketing for OpenTable.
diner_notes | **Optional.**  Notes submitted by the diner along with this reservation
diner_tags | **Optional.** Array of OpenTable specific diner tags

### Reservation States

Reservations will always be in one of the following states.

NAME | Description
--------- | -----------
BOOKED | The reservation has been made. All reservations must start off in this state.
SEATED | The party has arrived at the restaurant and ben seated.
ASSUMED_SEATED | Time for reservation has passed but reservation has not placed into one of the terminal states by the partner system (DONE, NOSHOW, CANCELED). *OpenTable will set reservations to this state as part of its daily shift maintenance.*
DONE | The reservation has been marked as 'Done' by the in-house staff.
NOSHOW | The diner failed to show at the restaurant.
CANCELED | The reservation has been canceled.

## Locking a Reservation

> OpenTable POST :: https://&lt;partner_callback_url&gt;/locks

```json
  {
    "rid": 1,
    "date": "2015-02-18T18:15:00Z",
    "covers": "calico",
    "expiration_seconds": 180,
    "turn_time_minutes": 90
  }
```

> Partner response

```json
  {
    "lock_id": "a192810120212", //assigned_by_partner
    "rid": 1,
    "date": "2015-02-18T18:15:00Z",
    "covers": "calico",
    "expiration_seconds": 180,
    "turn_time_minutes": 90
  }
```

This endpoint is called to reserve inventory while the diner completes the reservation process. The channel inventory system must hold the inventory booking until the expiration date is reached. If the expiration date is reached and the lock has not been cancelled then the underlying inventory can be released and used for other reservations.

### Entity

Parameter | Required | Description
--------- | ------- | -----------
rid | Yes | The restaurant id
lock_id | Yes | The id of the lock. This is assigned by the partner system and **must be globally unique**.
date | Yes | The UTC start date and time of the reservation
covers | Yes | The size of the party the booking is for
expiration_seconds | No | Number of seconds until the lock expires
turn_time_minutes | No | The length of time the reservation will be made for. This value is given in minutes.

## Making a new reservation

OpenTable will call the partner API whenever a diner is attempting to book a reservation. OpenTable will call the **lock** API prior to booking a reservation via a POST to the reservation entity. 

Other points of note:

* The href field in the reservation supplied by OpenTable when booking the reservation will remain valid only if OpenTable receives a valid response to its POST call to the reservation endpoint.
* The res_id field MUST be populated and returned by the partner API if the reservation is created in the partner's reservation system.
* Should there be a communication break prior ro OpenTable receiving a 201 (or other) response then OpenTable will attempt at least one retry to create the reservation. The retry attempt will have the same unique href as was specified in the first attempt at reservation creation.

### URL Detail

`https://<partner_callback_url>/reservations/<reservation_id>`

# Exchanging Reservation Updates

## Receiving Updates from OpenTable

OpenTable will PUT a reservation update message should any of the following reservation fields change.

* Party Size
* Reservation date and time

Providers should acknowledge the PUT with a 200 and update the sequence-id with a new value in order to help protect against collisions.

### URL Detail

`https://<partner_callback_url>/reservations/<reservation_id>`

### Entity

See [Reservations](#reservation)

<aside class="warning">Reservations cannot be moved across restaurants or systems. In order to move a reservation it must first be cancelled and then a new one made in the target restaurant.</aside>

## Sending Updates to OpenTable

Partner systems should perform a PUT to the OpenTable reservation system should any of the following reservation fields change.

* Party Size
* Reservation date and time

### URL Detail

`OpenTable href for the reservation. Please see reservation schema.`
