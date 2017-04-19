---
title: OpenTable Developer Guide - Restaurant API's

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

Welcome to the OpenTable Developer's Guide for using the Network Inventory and Guest Center Sync API. The following information will show you how to integrate with OpenTable's APIs for retrieving and managing reservations, guest details and inventory.

# Getting Started

Please begin by selecting the service of interest: 

1. Inventory API - available to groups for sharing available restaurant availability with OpenTable 
2. Guest Center Sync API - utilized by third party providers for read-only access to reservations and a restaurant guestlist.

## Guest Center API Overview

Integration with the Guest Center Sync API involves following steps:

1. Complete the SOC-2 security questionnaire 
2. Sign and consent to the OpenTable Developer Terms of Service (TOS) 
3. Confirm which restaurant(s) you wish to work with and have them sign applicable data sharing agreement 
4. Request a client id and client secret that are used for authorization
5. Make a sample 'guest' and 'reservation' pull request in the Pre-Production environment
6. Send and receive ongoing guest and reservation details by restaurant 


## Inventory Overview

Integration with the Inventory API involves following steps:

1. Obtain a client id and client secret that are used for authorization.
2. Register a restaurant to provide required metadata and a callback. This will create a restaurant profile in [www.opentable.com] (www.opentable.com) search results.
3. Publish your seating availability. This will enable diners to find available tables on [www.opentable.com] (www.opentable.com).
4. Accept reservation booking requests from OpenTable.
5. Send and receive reservation updates and cancellations.

## Payloads and Protocols

### Security

OpenTable uses OAuth 2.0 as the primary authorization mechanism. This means that an access token must be obtained and submitted with all requests. See [Authorization](#authorization) section for more details.OpenTable's Network Partner APIs can only be accessed via **HTTPS**. This applies to all environments. 

For developers wishing to use the Guest Center Sync API, prior access must be granted via the SOC-2 approval process. Click here to learn more. 

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

OpenTable has two separate environments. Each environment:

* corresponds to a different stage of the development process
* has different DNS names for the core services
* has it's own copy of the data. State is not shared across environments.

## Pre-Production
The Pre-Production **(PP)** environment is available once you are ready for final acceptance testing of your OpenTable integrations. Load testing can also be scheduled and performed in this environment.

Service Name | Service URL
--------- | -----------
Authentication | https://oauth-pp.opentable.com
Inventory Partner | https://restaurant-api-pp.opentable.com
Guest Center Developer | https://gc-sync-api-pp.opentable.com


## Production
The production services are the same ones accessed by the OpenTable.com web site. Your integration is live once it is communicating with the OpenTable production web services.

Service Name | Service URL
--------- | -----------
Authentication | https://oauth.opentable.com
Inventory Partner | https://restaurant-api.opentable.com
Guest Center Developer | https://gc-sync-api.opentable.com


<aside class="warning">Client ids need be specifically granted production access. Please contact us to request production privileges for your client id.</aside>

# Authorization

OpenTable uses [OAuth 2.0](https://tools.ietf.org/html/rfc6749) to authorize access to protected resources. Authorization involves following steps:

* Request client id and secret
* Obtain an access token using the issued client credentials
* Use the access token to access protected resources

## Requesting a Client Id

To request developer access, [send us an email](mailto:dchornyi@opentable.com; njoshi@opentable.com). Self-registration will be available soon.

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

> OpenTable Response :: HTTP 1.1 403 Forbidden

```json
    {
        "error": "no_rid_routing",
        "message": "No routing for RID:888"
    }
```

> OpenTable Response :: HTTP 1.1 403 Forbidden

```json
    {
        "error": "unknown_client_id",
        "message": "OAuth ClientID:<client-id> is not provisioned for umami-partner-service"
    }
```


* If the access token is present and valid, an appropriate response will be returned by the resource server.
* If the access token is missing HTTP 400 Bad Request is returned.
* If the access token is invalid or expired HTTP 401 Unauthorized is returned.
* If partner does not have access for specific RID, HTTP 403 Forbidden is returned with error "no_rid_routing"

# Registering a Restaurant

>Partner PUT :: https://restaurant-api.opentable.com/api/v1/&lt;partner_id&gt;/restaurants/&lt;rid&gt;

```json
  {
    "partner_restaurant_id": 12345
  }
```
> OpenTable response :: HTTP 1.1 200 OK


The setup entity is used to specify how the restaurant will integrate with OpenTable. This entry must be PUT to the server prior to the partner sending any availability updates. Availability updates sent prior to the setup being PUT will fail with an error code of 407 (unexpected).

### URI

`https://restaurant-api.opentable.com/api/v1/<partner_id>/restaurants/<rid>`

### Entity Fields

Member | Description
--------- | -----------
partner_restaurant_id | Restaurant id as defined by the partner system

# Availability

## Publishing Availability
Partners can inform OpenTable of availability by pushing the available inventory as a list of availability items; where an item is specified by a date, time, and party size that can be booked at the restaurant.

Partners specify multiple values for the time field in order to efficiently represent many items that apply to the same party size. Every time slot that is listed will have availability set to true. All omitted times will have availability set to false implicitly.

Once availability for a day and party size is posted, it can be updated by posting another availability for the same date and party size, but with different times. To remove all availability for a day, send an empty array of time.

OpenTable stores in 15 minutes intervals.

<aside class="notice">
For the availability endpoint all dates and times should be sent in restaurant local time.
</aside>

### V2 Publishing Availability

> Partner POST :: https://restaurant-api.opentable.com/api/v2/&lt;partner_id&gt;/availability

```json
{
  "rid" : 8675309,
  "date" : "2015-11-02",
  "sequence_id" : 1,
  "party_sizes" : {
    "1": ["18:45", "19:00"],
    "2": ["19:00", "19:15"],
    "3": []
  }
}
```
> OpenTable response :: HTTP 1.1 200 OK

### HTTP Request

`POST https://restaurant-api.opentable.com/api/v2/<partner_id>/availability`

### Entity

Member | Type | Description
--------- | ----------- | -----------
rid | Integer | OpenTable RID.
date | Date | The local date in ISO 8601
sequence_id | Integer | Sequence id is like a version number and is used to decide whether to overwrite previously received availability. When an availability update is received, the provided sequence id is compared with the highest sequence id for the combination of (rid, date, party size) that was received so far. If the new sequence id is higher, availability is updated; otherwise the update is ignored.
party_sizes | Map | Map of party sizes and their corresponding availability times in HH:mm 24-hour format. The mm can have values: 00, 15, 30, 45. Only availabilities specified here will be updated.

<aside class="notice">
Only party sizes specified in the request are processed. To clear availability for specific party size, this party size should be included in request, with empty list of times. In the example, the party size "3" would be cleared and Availability for party sizes 4-20 would not be changed.
</aside>

### V1 Publishing Availability

> Partner POST :: https://restaurant-api.opentable.com/api/v1/&lt;partner_id&gt;/availability

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

### HTTP Request

`POST https://restaurant-api.opentable.com/api/v1/<partner_id>/availability`

### Entity

Member | Type | Description
--------- | ----------- | -----------
rid | Integer | OpenTable RID.
date | Date | The local date in ISO 8601
party_size | Integer | The size of the party that may be booked at the time(s) specified
time | Array | An arry of times that have availability for the provided party size. All other times are set to false implicitly. Given as offsets in minutes from midnight.
sequence_id | Integer | Sequence id is like a version number and is used to decide whether to overwrite previously received availability. When an availability update is received, the provided sequence id is compared with the highest sequence id for the combination of (rid, date, party size) that was received so far. If the new sequence id is higher, availability is updated; otherwise the update is ignored.

## Checking Availability

> Partner GET :: https://restaurant-api.opentable.com/api/v1/&lt;partner_id&gt;/restaurants/&lt;rid&gt;/checkAvailability?partySize=&lt;party size&gt;&fromDatetime=&lt;from&gt;&toDatetime=&lt;to&gt;

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

> OpenTable POST :: https://&lt;partner_lock_url&gt;

```json
  {
    "rid": 1,
    "date": "2015-02-18T18:15",
    "party_size": 2
  }
```

> Partner response :: HTTP 200 OK

```json
  {
    "lock_id": 965665360, //assigned_by_partner
    "rid": 1,
    "date": "2015-02-18T18:15",
    "party_size": 2,
    "expiration_seconds": 180
  }
```

> Partner response :: HTTP 409 Conflict

```json
  {
    "error": "TBD",
    "error_description": "TBD"
  }
```

This endpoint is called to reserve inventory while the diner completes the reservation process. The channel inventory system must hold the inventory booking until the expiration date is reached. If the expiration date is reached and the lock has not been cancelled then the underlying inventory can be released and used for other reservations.

### Entity

Parameter | Type | Required | Description
--------- | ------- | ------- | -----------
rid | Integer | Yes | The restaurant id
lock_id | Long | Yes | The id of the lock. This is assigned by the partner system and will be used to make a reservation in a subsequent call. (See [Reservation Pattern](http://arnon.me/soa-patterns/reservation/))
date | Date|  Yes | The local start date and time of the reservation
party_size | Integer | Yes | The size of the party the booking is for
expiration_seconds | Long | No | Number of seconds until the lock expires

## Making a reservation

OpenTable will call the partner API whenever a diner is attempting to book a reservation. OpenTable will call the **lock** API prior to booking a reservation via a POST to the reservation entity. 

> Opentable POST :: https://&lt;partner_make_reservation_url&gt;

```json
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

> Partner Response :: HTTP 200 OK

```json
{
  "confirmation_number": 1,
  "rid": 888,
  "date_time": "2013-05-09T18:00",
  "party_size": 4
}
```

> Partner response :: HTTP 409 Conflict

```json
  {
    "error": "TBD",
    "error_description": "TBD"
  }
```

Other points of note:

* OpenTable do up to 3 total retries to lock, make, change, or cancel a reservation if it receives and HTTP 5xx response or a timeout. Retries are done with the same request parameters and body. 

### Entity (yet to determine which are optional)
Member | Description
--------- | -----------
rid | The rid that this reservation is assigned to
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
transactional_email | The email address of the diner for sending transactional email. This field can only be used for email marketing if opt_in_for_restaurant_marketing is set to **true**
opt_in_for_restaurant_marketing | Whether transactional_email can also be used for marketing
web_reso_notes | **Optional.**  Notes from Consumer Web (currently Redemption or Offer information)
guest_reso_notes | **Optional.** Notes submitted by the diner along with this reservation

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

`https://<partner_make_reservation_url>`

# Exchanging Reservation Updates

## Receiving Updates from OpenTable

OpenTable will POST a reservation update message should any of the following reservation fields change.

> OpenTable POST :: https://&lt;partner_update_reservation_url&gt;

```json
{
  "rid": 888,
  "date_time": "2013-05-09T18:00",
  "party_size": 4,
  "guest": {
    "gpid": 987,
    "first_name": "Ernest",
    "last_name": "Rivas",
    "transactional_email": "erivas@abc.com",
    "opt_in_for_restaurant_marketing": true,
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

> Partner Response :: HTTP 200 OK

```json
{
  "confirmation_number": 556,
  "rid": 888,
  "date_time": "2013-05-09T18:00",
  "party_size": 4
}
```

* Party Size
* Reservation date and time

### URL Detail

`https://<partner_update_reservation_url>`

### Entity

See [Reservation](#making-a-reservation)

<aside class="warning">Reservations cannot be moved across restaurants or systems. In order to move a reservation it must first be cancelled and then a new one made in the target restaurant.</aside>

## Receiving Cancels From Opentable

Opentable will POST a cancel  reservation message, containing the RID and confirmation_number of the reservation.

> OpenTable POST :: https://&lt;partner_cancel_reservation_url&gt;

```json
{
  "rid": 888,
  "confirmation_number": 1
}
```

> Partner Response

```json
{
  "rid": 888,
  "confirmation_number": 1
}
```

## Sending Updates to OpenTable

Partner systems should perform a POST to the OpenTable reservation system should any of the following reservation fields change.

* Party Size
* Reservation date and time
* Reservation Status

> Partner POST :: https://restaurant-api.opentable.com/resoupdate/resoupdate

```json
{
  "ConfirmationNumber" : 123,
  "DateTime" : "2015-07-03 19:00",
  "PartySize" : 2,
  "ReservationState" : "Cancelled",
  "RID" : "1107",
  "SequenceNumber" : 0,
  "ServerName" : "Server1",
  "UpdateDT_UTC" : "2015-06-17 20:35"
}
```

### Request Entity

Member | Type | Description | Usage
------- | ---- |------------ | -----
ConfirmationNumber | Int32 | Reservation Confirmation Number | Required (>0)
DateTime | String | Reservation Date and Time | Required
PartySize | INT32 | Party Size | Required for Pending, Seated, AssumedSeated (>0)
ReservationState | String | State of the Reservation | Required. Acceptable Values : Pending, Seated, AssumedSeated, Cancelled, NoShow
RID | Int32 | Restaurant ID | Required
SequenceNumber | Int32 | Must always be 0 | Required
ServerName | String | Server Name | Optional
UpdatedDT_UTC | String | Update Date in UTC | Required

### Response Entity
None.


### Response Status Codes
Status Code | Description
------------ | ----------
200 | OK
400 | Invalid Parameters (Bad Request)
404 | DB is unavailable, try again later. 



## Echo backs

Echo-backs are designed to prevent "ghost" bookings in a partner's reservation system if there is a failure in the OT booking process after the Make has been sent to a partner. The idea is to issue the [Reservation Update](#sending-updates-to-opentable) API call after a reservation is saved to the Partner's database and processing of the "Make" call is finished (response is sent to OpenTable). This will allow OpenTable to check the existence of the booking confirmation number against it's internal database and in the case where a booking does not exist, OpenTable will issue a cancel request.

## FRN Recovery

This API is designed to trigger direct restaurant communication to determine if the given restaurant is online and reachable. This is the workflow:
* OpenTable tracks failures of the Lock/Make/Update/Cancel API calls per each RID
* After 3 failures in 5 minutes, OpenTable marks this restaurant with an "FRN" (False Reserve Now) state. This removes the ability to book this restaurant from OpenTable website.
* For FRN restaurants, OpenTable periodically calls the "FRN recovery" endpoint to check if the restaurant is back online.
* In the case "FRN Recovery" returns success,  OpenTable removes the FRN status from this restaurant and the restaurant becomes bookable.

### Receiving FRN Recovery Checks from OpenTable

> OpenTable GET :: https://&lt;partner_frn_url&gt;?rid=<rid>

> Partner Response :: HTTP 200 OK

```json
{
    "rid": 1,
    "online": true
}

```
Any other response code would indicate check failure. There is special case when rid is incorrectly provisioned and it is not exists in the partner's database. To indicate such case, partner could implement the following response:

> Partner Response :: HTTP 400 Bad request

```json
{
    "error": "ECannotFindRestaurant"
}

```

# Integration Testing
These APIs act as the entry point from the consumer's side when making a reservation.

Hosts:

CI: `reservation-na-ci.otenv.com`

PP: `reservation-na-pp.otenv.com`

Prod: `reservation-na-sc.otenv.com`

## Test Locking a Reservation

> POST :: `/reservation/v1/restaurants/<rid>/slotlocks`

```
{
  "ReservationDateTime"  : "2015-04-18T19:30",
  "PartySize" : 10
}
```

> Response

```
{
  "statusCode": 0,
  "statusMessage": "Success",
  "restaurantId": 117784,
  "reservationDateTime": "2015-04-18T19:30",
  "partySize": 10,
  "slotLockId": 667520417,
  "offerSlotLockId": 0,
  "errorMessage": null
}
```
### Request URL Parameters
**rid**: The unique ID of the restaurant


### Request Entity

Member | Type | Description | Usage
------- | ---- |------------ | -----
ReservationDateTime | string | ISO format Date and Time string in the form: "YYYY-MM-DDTHH:mm" | Required
PartySize | integer | Size of dining party | Required

### Response Entity

Member | Type | Description
------- | ---- |---------
restaurantId | integer | The unique ID of the restaurant (RID)
statusCode | integer | 0 denotes success, any positive value denotes a failure
statusMessage | integer | Either "Success" or "Error"
slotLockId | integer | Numeric slot lock id which can be used to make a booking subsequently
offerSlotLockId | integer | Defaults to 0, can be ignored
errorMessage | string | Detailed error message if exists

### Response Status Codes

Status Code | Description
----------- | -----------
200 | Successful
404 | Not found
409 | Conflict

## Test Making a Reservation

> POST  :: `/reservation/v1/restaurants/<rid>/reservations`

```
{
  "ReservationDateTime" : "2014-03-01T19:00",
  "PartySize" : 2,
  "SlotLockId" : 123,
  "UserGpid" : 130033826163,
  "DinerGpid" : 130033826163,
  "DinerCallerCustomerId" : 0,
  "DinerReservationNotes" : "special birthday dinner",
  "DinerPhone" : {
    "PhoneNumber" : "2123134114",
    "CountryId" : "BR",
    "PhoneType" : "Mobile"
  },
  "PointsType" : "POP"
}
```

> Response

```
{
  "statusCode": 0,
  "statusMessage": "Success",
  "restaurantId": 95152,
  "reservationDateTime": "2014-03-02T19:00",
  "partySize": 2,
  "confirmationNumber": 2252511,
  "offerConfirmationNumber": 0,
  "points": 1000,
  "pointsRule": "DIPAwardedPoints",
  "violations": [],
  "sameDayCutoff": null,
  "earlyCutoff": null,
  "overlappingReservations": [],
  "errorMessage": null,
  "securityToken": "01h-RR0vBzpeI8jkYhsNNPOnrNF9Q1"
}
```

### Request URL Parameters
**rid**: The unique ID of the restaurant

### Request Entity

Member | Type | Description | Usage
------- | ---- |------------ | -----
ReservationDateTime | string | ISO format Date and Time string in the form: "YYYY-MM-DDTHH:mm" | Required
PartySize | integer | Size of dining party | Required
SlotLockId | integer | Numeric slot lock id which can be used to make a booking subsequently | Required
UserGpid | long | Global Person Id of the website user. | Required
DinerGpid | long | Global Person Id of the diner.  *Either DinerGpid or DinerCallerCustomerId (below) is required. | Required
DinerCallerCustomerId | integer | If this is a caller-created reservation, this is the cust id of the diner. | Required
DinerPhone | struct | Contact phone for the diner.  Contains the string-valued fields PhoneNumber, CountryId, and PhoneType. CountryId is a standard 2 letter country abbreviation – e.g., "BR" for Brazil. PhoneType is either "Home", "Work", or "Mobile". | Required
PointsType | string | Either "POP", "Standard", or "None" (one of the PointsType values returned by the availability service.) This is used to specify the maximum allowed points for the reservation. Note that it may not be possible for the service to award the maximum points; For example, if PointsType = "POP" but the reservation time is not POP, standard points are awarded. | Required
DinerReservationNotes | string | Notes from the diner to the restaurant. | Optional

### Response Entity

Member | Type | Description
------- | ---- |---------
statusCode | integer | 0 denotes success, positive value denotes failure
statusMessage | integer | Either "Success" or "Error"
restaurantId | integer | The unique ID of the restaurant (RID)
offerSlotLockId | integer | Defaults to 0, can be ignored
errorMessage | string | Detailed error message if exists
confirmationNumber |integer | numeric identifier for the reservation

### Response Status Codes

Status Code | Description
----------- | -----------
201 | Created, Successful
404 | Not found
409 | Conflict

## Test Canceling a Reservation

> PUT `/reservation/v1/restaurants/<rid>/confirmations/<confirmation_number>`

```
{
  "ReservationState" : "Canceled"
}
```

> Response

```

{
  "statusCode": 0,
  "statusMessage": "Success",
  "restaurantId": 95152,
  "confirmationNumber": 2252511,
  "offerConfirmationNumber": 0,
  "violations": [],
  "sameDayCutoff": null,
  "earlyCutoff": null,
  "errorMessage": null
 }
 ```

### Request URL Parameters

**rid**: The unique ID of the restaurant
**confirmation_number**: Numeric reservation identifier

### Request Entity
Member | Type | Description | Usage
------- | ---- |------------ | -----
ReservationState | string | The string "Canceled". | Required 

### Response Entity

Member | Type | Description
------- | ---- |---------
statusCode | integer | 0 denotes success, positive value denotes failure
statusMessage | integer | Either "Success" or "Error"
restaurantId | integer | The unique ID of the restaurant (RID)
confirmationNumber |integer | numeric identifier for the reservation
errorMessage | string | Detailed error message if exists

### Response Status Codes

Status Code | Description
----------- | -----------
200 | Successful
204 | No Content - Reservation already canceled.
404 | Not found - Reservation does not exist
409 | Conflict


## Test Changing a Reservation

> PUT `/reservation/v1/restaurants/<rid>/confirmations/<confirmation_number>`

```
{
  "ReservationDateTime" : "2014-03-01T19:00",
  "PartySize" : 2,
  "SlotLockId" : 123,
  "UserGpid" : 130033826163,
  "DinerGpid" : 130033826163,
  "DinerCallerCustomerId" : 0,
  "DinerReservationNotes" : "special birthday dinner",
  "DinerPhone" : {
    "PhoneNumber" : "2123134114",
    "CountryId" : "BR",
    "PhoneType" : "Mobile"
  },
  "PointsType" : "POP"
}
```

> Response

```

{
  "statusCode": 0,
  "statusMessage": "Success",
  "restaurantId": 95152,
  "reservationDateTime": "2014-03-02T19:00",
  "partySize": 2,
  "confirmationNumber": 2252511,
  "offerConfirmationNumber": 0,
  "points": 1000,
  "pointsRule": "DIPAwardedPoints",
  "violations": [],
  "sameDayCutoff": null,
  "earlyCutoff": null,
  "overlappingReservations": [],
  "errorMessage": null,
  "securityToken": "01h-RR0vBzpeI8jkYhsNNPOnrNF9Q1"
}
```

### Request URL Parameters
**rid**: The unique ID of the restaurant
**confirmation_number**: Numeric reservation identifier

### Request Entity

Member | Type | Description | Usage
------- | ---- |------------ | -----
ReservationDateTime | string | ISO format Date and Time string in the form: "YYYY-MM-DDTHH:mm" | Required
PartySize | integer | Size of dining party | Required
SlotLockId | integer | Numeric slot lock id which can be used to make a booking subsequently | Required
UserGpid | long | Global Person Id of the website user. | Required
DinerGpid | long | Global Person Id of the diner.  *Either DinerGpid or DinerCallerCustomerId (below) is required. | Required
DinerCallerCustomerId | integer | If this is a caller-created reservation, this is the cust id of the diner. | Required
DinerPhone | struct | Contact phone for the diner.  Contains the string-valued fields PhoneNumber, CountryId, and PhoneType. CountryId is a standard 2 letter country abbreviation – e.g., "BR" for Brazil. PhoneType is either "Home", "Work", or "Mobile". | Required
PointsType | string | Either "POP", "Standard", or "None" (one of the PointsType values returned by the availability service.) This is used to specify the maximum allowed points for the reservation. Note that it may not be possible for the service to award the maximum points; For example, if PointsType = "POP" but the reservation time is not POP, standard points are awarded. | Required
DinerReservationNotes | string | Notes from the diner to the restaurant. | Optional

### Response Entity

Member | Type | Description
------- | ---- |---------
statusCode | integer | 0 denotes success, positive value denotes failure
statusMessage | integer | Either "Success" or "Error"
restaurantId | integer | The unique ID of the restaurant (RID)
offerSlotLockId | integer | Defaults to 0, can be ignored
errorMessage | string | Detailed error message if exists
confirmationNumber |integer | numeric identifier for the reservation

### Response Status Codes
Status Code | Description
----------- | -----------
200 | Created, Successful
404 | Not found
409 | Conflict
