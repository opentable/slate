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

Welcome to the [OpenTable](https://www.opentable.com) Developer's Guide. This guide is will show you how to integrate with OpenTable's APIs to manage your restaurants, reservations, and inventory.

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
Network Partner | https://restaurant-api-ci.opentable.com

## Pre-Production
The Pre-Production **(PP)** environment is available once you are ready for final acceptance testing of your OpenTable integrations. Load testing can also be scheduled and performed in this environment.

Service Name | Service URL
--------- | -----------
Authentication | https://oauth-pp.opentable.com
Network Partner | https://restaurant-api-pp.opentable.com

## Production
The production services are the same ones accessed by the OpenTable.com web site. Your integration is live once it is communicating with the OpenTable production web services.

Service Name | Service URL
--------- | -----------
Authentication | https://oauth.opentable.com
Network Partner | https://restaurant-api.opentable.com

<aside class="warning">Client ids need be specifically granted production access. Please contact us to request production privileges for your client id.</aside>

# Authorization

OpenTable uses [OAuth 2.0](https://tools.ietf.org/html/rfc6749) to authorize access to protected resources. Authorization involves following steps:

* Request client id and secret
* Obtain an access token using the issued client credentials
* Use the access token to access protected resources

## Requesting a Client Id

To request developer access, [send us an email](mailto:dchornyi@opentable.com). Self-registration will be available soon.

## Obtaining an Access Token

> POST :: https://oauth.opentable.com/api/v2/oauth/token?grant_type=client_credentials

> OpenTable response :: HTTP 1.1 200 OK

```json
    {
        "access_token": "a1c7b724-0a20-42be-9dd4-23d873db1f9b",
        "token_type": "bearer",
        "expires_in": 2419181,
        "scope": "DEFAULT"
    }
```

Clients can obtain an access token using the [OAuth 2.0 client credentials flow](https://tools.ietf.org/html/rfc6749#section-4.4).

### URI

`https://oauth.opentable.com/api/v2/oauth/token?grant_type=client_credentials`

### Request Parameters

Member | Description
--------- | -----------
grant_type | OAuth grant type. Should be "client_credentials"

### Submitting Client Credentials

Client credentials are submitted in the `Authorization` header as defined in the [OAuth spec](https://tools.ietf.org/html/rfc6749#section-2.3).
Given a client id (e.g., "client_id") and a client secret (e.g., "client_secret"), you need to do the following:

1. Concatenate them using a ":" (e.g., "client_id:client_secret")
2. Base64 encode the result from step 1 (e.g., "Y2xpZW50X2lkOmNsaWVudF9zZWNyZXQ=")
3. Set the header "Authorization: Basic <result from step 2>" (e.g., "Authorization: Basic Y2xpZW50X2lkOmNsaWVudF9zZWNyZXQ=")

## Authorizing Requests

> Authorization: bearer a1c7b724-0a20-42be-9dd4-23d873db1f9b")

1. [Obtain an access token](#obtaining-an-access-token)
2. Set the header "Authorization: bearer <result from step 1>" (e.g., "Authorization: bearer a1c7b724-0a20-42be-9dd4-23d873db1f9b")
3. Send the request
    a. If the token is valid and not expired, an appropriate response from the resource server will be returned.
    b. If the token is not valid, the resource server responds using the appropriate HTTP status code (typically, 400, 401, 403, or 405) and an error code [https://tools.ietf.org/html/rfc6750#section-3.1](https://tools.ietf.org/html/rfc6750#section-3.1)

### Responses

> OpenTable Response :: HTTP 1.1 400 Bad Request

```json
    {
        "error": "invalid_request",
        "message": "oauth token is required to access this resource"
    }
```

> OpenTable Response :: HTTP 1.1 401 Unauthorized

```json
    {
        "error": "invalid_token",
        "message": "b7721d39-65f6-4b6a-8686-3af5246e5b3a"
    }
```

* If the access token is present and valid, an appropriate response will be returned by the resource server.
* If the access token is missing HTTP 400 Bad Request is returned.
* If the access token is invalid or expired HTTP 401 Unauthorized is returned.

# Registering a Restaurant

>Partner PUT :: https://np.opentable.com/&lt;partner_id&gt;/restaurants/&lt;rid&gt;

```json
  {
    "partner_restaurant_id": 12345
  }
```
> OpenTable resopnse :: HTTP 1.1 200 OK


The setup entity is used to specify how the restaurant will integrate with OpenTable. This entry must be PUT to the server prior to the partner sending any availability updates. Availability updates sent prior to the setup being PUT will fail with an error code of 407 (unexpected).

### URI

`https://restaurant-api.opentable.com/api/v1/<partner_id>/restaurants/<rid>`

### Entity Fields

Member | Description
--------- | -----------
partner_restaurant_id | Restaurant id as defined by the partner system

# Availability

## Publishing Availability

> Partner POST :: https://restaurant-api.opentable.opentable.com/api/v1/&lt;partner_id&gt;/availability

```json
  [
      {
      "rid" : 8675309,
      "date" : "2015-05-02",
      "party_size" : 2,
      "time" : [420, 435, 450, 465],
      "sequence_id" : 1
      } ,
      {
        "rid": 8675309,
        "date": "2015-05-02",
        "party_size" : 3,
        "time": [420, 435],
        "sequence_id" : 2
      }
  ]
```
> OpenTable response :: HTTP 1.1 200 OK
```

Partners can inform OpenTable of availability by pushing the available inventory as a list of availability items; where an item is specified by a date, time, and party size that can be booked at the restaurant.

Partners specify multiple values for the time field in order to efficiently represent many items that apply to the same party size. Every time slot that is listed will have availability set to true. All omitted times will have availability set to false implicitly.

Once availability for a day and party size is posted, it can be updated by posting another availability for the same date and party size, but with different times. To remove all availability for a day, send an empty array of time.

<aside class="notice">
For the availability endpoint all dates and times should be sent in restaurant local time.
</aside>

### HTTP Request

`POST https://restaurant-api.opentable.com/<partner_id>/availability`

### Entity

Member | Description
--------- | -----------
rid | The restaurant id.
date | The local
party_size | The size of the party that may be booked at the time(s) specified
time | An arry of times that have availability for the provided party size. All other times are set to false implicitly. Given as offsets in minutes from midnight.
sequence_id | Sequence id is like a version number and is used to decide whether to overwrite previously received availability. When an availability update is received, the provided sequence id is compared with the highest sequence id for the combination of (rid, date, party size) that was received so far. If the new sequence id is higher, availability is updated; otherwise the update is ignored.

## Checking Availability

> Partner GET :: https://restaurant-api.opentable.opentable.com/api/v1/&lt;partner_id&gt;/restaurants/&lt;rid&gt;/checkAvailability?partySize=&lt;party size&gt;&fromDatetime=&lt;from&gt;&toDatetime=&lt;to&gt;

> OpenTable response :: HTTP 1.1 200 OK
```json
  [
      {
          "Rid": 123456,
          "IsAvailable": false,
          "SequenceNumber": 1109,
          "Time": "2015-05-02T07:00:00"
      },
      {
          "Rid": 123456,
          "IsAvailable": false,
          "SequenceNumber": 1109,
          "Time": "2015-05-02T07:15:00"
      },
      {
          "Rid": 123456,
          "IsAvailable": false,
          "SequenceNumber": 1109,
          "Time": "2015-05-02T07:30:00"
      }
  ]
```

Availability that is published to the API will eventually appear on the consumer web site. This endpoint reflects the same availability data that OpenTable.com consumer web site uses.

<aside class="notice">
For the availability endpoint all dates and times should be sent in restaurant local time.
</aside>

### HTTP Request

`GET https://restaurant-api.opentable.com/api/v1/<partner_id>/restaurants/<rid>/checkAvailability?partySize=<party size>&fromDatetime=<from>&toDatetime=<to>`

### Request parameters

Member | Description
--------- | -----------
rid | The restaurant id.
party_size | The size of the party that may be booked at the time(s) specified
from | starting date and time for the availability check (e.g., 2015-03-28T19:00)
to | ending date and time for the availability check (e.g., 2015-03-28T22:15)

# Booking a Reservation

The partner data store is considered the source of truth for reservation information. Reservations cannot be created, changed, or canceled without first being communicated to the partner's api endpoints. OpenTable will always sek to make a reservation with a lock id specified. The lock id may refer to an ephemeral lock that has been discarded. In these cases OpenTable expects the partner api to attempt to book the reservation an a 'best efforts' basis as the underlying inventory may have been taken by another diner.

## Locking a Reservation

> OpenTable POST :: https://&lt;partner_callback_url&gt;/locks

```json
  {
    "rid": 1,
    "date": "2015-02-18T18:15",
    "party_size": 2,
    "expiration_seconds": 180,
    "turn_time_minutes": 90
  }
```

> Partner response

```json
  {
    "lock_id": 965665360, //assigned_by_partner
    "rid": 1,
    "date": "2015-02-18T18:15",
    "party_size": 2,
    "expiration_seconds": 180,
    "turn_time_minutes": 90
  }
```

This endpoint is called to reserve inventory while the diner completes the reservation process. The channel inventory system must hold the inventory booking until the expiration date is reached. If the expiration date is reached and the lock has not been cancelled then the underlying inventory can be released and used for other reservations.

### Entity

Parameter | Required | Description
--------- | ------- | -----------
rid | Yes | The restaurant id
lock_id | Yes | The id of the lock. Must be a number. This is assigned by the partner system and **must be globally unique**.
date | Yes | The local start date and time of the reservation
party_size | Yes | The size of the party the booking is for
expiration_seconds | No | Number of seconds until the lock expires
turn_time_minutes | No | The length of time the reservation will be made for. This value is given in minutes.

## Making a reservation

OpenTable will call the partner API whenever a diner is attempting to book a reservation. OpenTable will call the **lock** API prior to booking a reservation via a POST to the reservation entity. 

> Opentable POST :: https://&ltpartner_api&gt

```
{
  "rid": 888,
  "date_time": "2013-05-09T18:00",
  "party_size": 4,
  "guest": {
    "gpid": 987,
    "first_name": "Ernest",
    "last_name": "Rivas",
    "email": "erivas@abc.com",
    "phone": {
      "number": "555.666.7777",
      "type": "Mobile",
      "country_code": 1
    }
  },
  "guest_reso_notes": "Red red wine",
  "web_reso_notes": "web notes",
  "lock_id": 965665360
}
```

> Partner Response

```
{
  "confirmation_number": 1,
  "rid": 888,
  "date_time": "2013-05-09T18:00",
  "party_size": 4
}
```

Other points of note:

* The href field in the reservation supplied by OpenTable when booking the reservation will remain valid only if OpenTable receives a valid response to its POST call to the reservation endpoint.
* The res_id field MUST be populated and returned by the partner API if the reservation is created in the partner's reservation system.
* Should there be a communication break prior ro OpenTable receiving a 201 (or other) response then OpenTable will attempt at least one retry to create the reservation. The retry attempt will have the same unique href as was specified in the first attempt at reservation creation.

### Entity (yet to determine which are optional)
Member | Description
--------- | -----------
rid | The rid that this reservation is assigned to
?href | The href that can be used to retrieve the reservation details from OpenTable
lock_id | **Optional.** The id of the inventory lock acquired for this reservation.
confirmation_number | Confirmation number for the reservation.
lock_id | lock id for the reservation
date_time | Datetime of the reservation.
party_size | The party size of the reservation
first_name | The first name of the diner
last_name | The last name of the diner
number | **Optional.** The phone number for the diner for this reservation
type | **Optional.** The phone type for the diner for this reservation
country_code | **Optional.** The phone type for the diner for this reservation
email | **Optional.** The email address of the diner. This field will only be present if the diner has opted into email marketing for OpenTable.
web_reso_notes | **Optional.**  Notes submitted by the diner along with this reservation
guest_reso_notes | **Optional.**

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

### URL Detail

`https://<partner_callback_url>/reservations/<reservation_id>`

# Exchanging Reservation Updates

> Opentable POST :: https://&ltpartner_api&gt

```
{
  "rid": 888,
  "date_time": "2013-05-09T18:00",
  "party_size": 4,
  "guest": {
    "gpid": 987,
    "first_name": "Ernest",
    "last_name": "Rivas",
    "email": "erivas@abc.com",
    "phone": {
      "number": "555.666.7777",
      "type": "Mobile",
      "country_code": 1
    }
  },
  "guest_reso_notes": "Red red wine",
  "web_reso_notes": "web notes",
  "confirmation_number": 556
}
```

> Partner Response

```
{
  "confirmation_number": 556,
  "rid": 888,
  "date_time": "2013-05-09T18:00",
  "party_size": 4
}
```

## Receiving Updates from OpenTable

OpenTable will PUT a reservation update message should any of the following reservation fields change.

* Party Size
* Reservation date and time

Providers should acknowledge the PUT with a 200.

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
