# BD_MART API Documentation Format Guidelines

## Consistent Response Structure
All BD_MART APIs follow a unified JSON response format for predictable frontend integration:

```json
// ✅ SUCCESS RESPONSE
{
  "status": "success",
  "message": "Optional success message (e.g., 'Product created successfully')",
  "data": { ... },             // Response payload
  "meta": { ... }              // Pagination, counts, metadata (optional)
}

// ✅ ERROR RESPONSE
{
  "status": "error",
  "message": "Human-readable error description",
  "error": { ... }             // Detailed error (development only, omit in production)
}
```

## API Response Cheat Sheet

| **Endpoint** | **Status Code** | **Success Format** | **Error Format** |
|---|---|---|---|
| `POST /auth/register` | 201 | `{ status: "success", data: { user }, message: "Account created" }` | `{ status: "error", message: "Email already exists" }` |
| `GET /products` | 200 | `{ status: "success", data: [...], meta: { page, limit, total } }` | `{ status: "error", message: "Filter error" }` |
| `POST /cart` | 200 | `{ status: "success", data: { items, total }, message: "Added to cart" }` | `{ status: "error", message: "Product out of stock" }` |
| `POST /orders` | 201 | `{ status: "success", data: { orderId, total }, message: "Order created" }` | `{ status: "error", message: "Cart is empty" }` |
| `GET /auth/me` | 200 | `{ status: "success", data: { user } }` | `{ status: "error", message: "Unauthorized" }` |
| `POST /payments/intent` | 200 | `{ status: "success", data: { clientSecret } }` | `{ status: "error", message: "Payment failed" }` |

## Error Codes Reference

| **Code** | **Meaning** | **Example Message** |
|---|---|---|
| 400 | Bad Request | "Invalid input data", "Product stock insufficient" |
| 401 | Unauthorized | "Missing or invalid token", "Token expired" |
| 403 | Forbidden | "Insufficient permissions", "Admin only endpoint" |
| 404 | Not Found | "Product not found", "Order not found" |
| 409 | Conflict | "Email already registered", "Item already in cart" |
| 422 | Unprocessable | "Validation failed", "Required field missing" |
| 500 | Internal Server | "Unexpected error, try again later" |

## Versioning Strategy
- Current: `v1` (all endpoints under `/api/v1/`)
- Future: `v2` when breaking changes needed
- Deprecation: Announce 6 months before deprecating `v1`
- Backward: Maintain `v1` while releasing `v2`

## Rate Limits (Per IP)

| **Endpoint Type** | **Limit** | **Window** |
|---|---|---|
| Auth endpoints (login/register) | 10 requests | per 15 minutes |
| Public product browsing | 100 requests | per 15 minutes |
| Auth-protected endpoints | 100 requests | per 15 minutes |
| Cart operations | 50 requests | per 15 minutes |
| Order creation | 5 requests | per 15 minutes |

## Documentation Generated With
- **Postman Collection**: `BD_MART_API.postman_collection.json` (included in repo)
- **Swagger/OpenAPI**: Auto-generated from Hasura + custom annotations
- **Human-readable**: This README with endpoint descriptions
- **Developer Onboarding**: New team members can understand API in < 30 minutes