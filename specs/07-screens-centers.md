# Responsibility Centers and Obligations Screen Spec

## 1. Purpose

Manage:
- responsibility centers
- obligations attached to centers

## 2. Center Management

### List centers
- Endpoint: `GET /rest/v1/responsibility_centers?user_id=eq.<id>&order=created_at.asc`

### Create center
- Endpoint: `POST /rest/v1/responsibility_centers`
- Required fields:
  - `user_id`
  - `name`
  - `icon`
  - `color`
  - `is_default` (usually `false` for custom)

### Update center
- Endpoint: `PATCH /rest/v1/responsibility_centers?id=eq.<center_id>`

### Delete center
- Endpoint: `DELETE /rest/v1/responsibility_centers?id=eq.<center_id>`

## 3. Obligation Management

### List
- Endpoint: `GET /rest/v1/obligations?user_id=eq.<id>&order=created_at.desc`

### Create
- Endpoint: `POST /rest/v1/obligations`
- Required:
  - `user_id`, `center_id`, `title`, `amount`, `currency`, `type`

### Update
- Endpoint: `PATCH /rest/v1/obligations?id=eq.<obligation_id>`

### Delete
- Endpoint: `DELETE /rest/v1/obligations?id=eq.<obligation_id>`

## 4. UI Requirements

- Group obligations by center.
- Show amount and completion state.
- Quick toggle completion from list.
- Wizard/modal for adding center and obligation.

## 5. Validation

- `name` non-empty for centers.
- `title` non-empty and `amount > 0` for obligations.
- `type` in `monthly | one-time`.


