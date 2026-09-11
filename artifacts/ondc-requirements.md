ONDC categorizes catalog data into **Mandatory Critical Attributes** (network and protocol requirements), **Mandatory Informational Attributes** (statutory legal obligations), and **Optional Attributes** (enrichment for discovery and conversion).

| Attribute Classification | Required on ONDC?           | Purpose                                                                |
| ------------------------ | --------------------------- | ---------------------------------------------------------------------- |
| **Mandatory Critical**   | **Yes** (Strictly enforced) | Enables protocol routing, stock matching, pricing, and buyer checkout. |

|
| **Mandatory Informational** | **Yes** (Legally required) | Satisfies Consumer Protection (E-Commerce) Rules 2020 and Legal Metrology.

|
| **Optional / Desirable** | **No** (Recommended) | Improves search ranking, rich display, and conversion on buyer apps.

|

---

**Mandatory Critical Attributes (Protocol & Transactional)**

Omitting any of these will trigger schema validation errors (`NACK`) at the ONDC Gateway or cause Buyer Apps to drop the item:

- **Unique Item ID (`id`)**: The persistent SKU or item identifier inside your database.

- **Title / Name (`descriptor.name`)**: Product title clearly stating what the item is.

- **Category Mapping (`category_id`)**: The official ONDC retail taxonomy code (e.g., `RET12` for Fashion/Textiles or `RET16` for Home/Decor).

- **Fulfillment & Location IDs (`fulfillment_id`, `location_id`)**: Links the item to a pickup workshop address and shipping serviceability zone.

- **Selling Price (`price.value`)**: The actual transaction price charged to the consumer (in INR).

- **Maximum Retail Price (`price.maximum_value`)**: Benchmark MRP; by law, `value` cannot exceed `maximum_value`.

- **Inventory Availability (`quantity.available.count`)**: Integer count of units currently in stock.

- **Primary Product Image (`descriptor.images`)**: At least one high-resolution image URL (though Buyer Apps generally require 2–3 angles to surface listings prominently).

- **Ready-to-Ship SLA (`@ondc/org/time_to_ship`)**: Courier handover window formatted in ISO 8601 duration (e.g., `PT24H` or `PT48H`).

- **Return & Cancellation Flags**: Boolean flags declaring `@ondc/org/returnable`, `@ondc/org/cancellable`, and `@ondc/org/available_on_cod`.

- **Return Window SLA (`@ondc/org/return_window`)**: Mandatory if the item is returnable (e.g., `P7D` for 7 days).

---

**Mandatory Informational Attributes (Statutory Disclosures)**

Under the Consumer Protection (E-Commerce) Rules 2020 and Legal Metrology Packaged Commodities rules, these must be declared under `items.tags`:

- **Country of Origin**: Must explicitly declare the country code (e.g., `IND`).

- **Manufacturer & Packer Details**: Legal name and registered workshop or production address.

- **Net Quantity & Unit of Measure**: Exact contents in the package (e.g., `1 piece`, `500 grams`, or `6.2 meters`).

- **Customer Support / Grievance Redressal**: Mandatory grievance officer or helpline contact details (phone number and email).

- **Generic Name of Commodity**: Plain descriptor of the physical good (e.g., "Saree", "Clay Pot", "Brass Lamp").

---

**Optional Attributes (Discovery & Conversion Boosters)**

These fields are not enforced by protocol validation, but leaving them out means lower search ranking on apps like Paytm or Mystore:

- **Long Description (`descriptor.long_desc`)**: Extended artisanal story, historical background, and detailed styling copy.

- **Short Description (`descriptor.short_desc`)**: Brief 1–2 line summary used in mobile search preview cards.

- **Rich Media**:
- **Brand Symbol / Logo (`descriptor.symbol`)**.

- **Audio Snippet (`descriptor.audio`)**: Can carry the artisan's voice narration or heritage description.

- **3D / AR Assets (`descriptor.3d_render`)**.

- **Trade Identifiers**: HSN (Harmonized System of Nomenclature) code, EAN/UPC barcodes, or GS1 numbers (often waived for micro-enterprises and unregistered artisans, but standard for retail).

- **Variant & Customization Hierarchy**: Color options, pattern groupings, or size scales (`tags.parent_item_id`).

- **Package Physical Dimensions**: Packed parcel metrics ($L \times W \times H$ in cm, gross weight in grams) to assist dynamic courier shipping calculations.

- **Care & Usage Instructions**: Material-specific maintenance guidelines (e.g., "Dry Clean Only" or "Fragile Terracotta").

- **Promotional Attributes**: Minimum order quantities (MOQ) or bulk discount tiers.
