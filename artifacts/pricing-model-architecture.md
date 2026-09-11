# Multimodal Pricing Regression Model (Phase 2)

> **Status:** Planning / Data Collection  
> **Target Deployment:** Phase 2 (Server-side Kaggle Backend)  
> **Model Type:** XGBoost Regressor + CLIP ViT-B/32 (Multimodal)

To ensure rural artisans receive fair compensation while remaining competitive, KalaKriti AI employs a two-stage pricing engine. Stage 1 (Statutory Floor) is a deterministic calculation ensuring minimum wages. Stage 2 (Market-Aware Pricing) uses machine learning to predict optimal D2C and B2B pricing.

---

## Stage 1: Statutory Cost Floor ($C_{\text{floor}}$)

A non-negotiable minimum calculation anchored to government standards. This acts as a hard boundary (Remuneration Guarantee) — the system blocks any listings priced below this floor to prevent predatory distress sales.

**Formula:**
$$C_{\text{floor}} = M_{\text{raw}} + (T_{\text{days}} \times W_{\text{statutory}} \times K_{\text{skill}}) + O_{\text{overhead}}$$

**Variables:**
*   **$M_{\text{raw}}$**: Stated raw material expenses (yarn, dyes, brass, clay). Extracted from dialect audio via the voice pipeline.
*   **$T_{\text{days}}$**: Verified production effort (labor days recorded via voice transcription).
*   **$W_{\text{statutory}}$**: Central/State statutory minimum wage rate for skilled artisans. Benchmarked at **₹450–₹600/day** under Ministry of Labour & Employment norms.
*   **$K_{\text{skill}}$**: Skill level multiplier:
    *   `1.0`: Basic craftsman
    *   `1.25`: Specialized GI-cluster artisan
    *   `1.5`: Master Weaver / National Awardee
*   **$O_{\text{overhead}}$**: 10% fixed allowance for packaging, local transit, and utilities.

---

## Stage 2: Market-Aware Fair Corridor ($P_{\text{fair}}, P_{\text{prem}}$)

Once the wage floor is locked, an AI model suggests the optimal consumer pricing based on current market trends and visual quality.

### Architecture

1.  **Vision Embeddings (CLIP ViT-B/32):** The studio-processed image of the product is passed through OpenAI's CLIP model to extract a 512-dimensional visual feature vector. This captures the aesthetic appeal, intricacy, and visual quality of the craft.
2.  **Textual/Categorical Features:** Craft category, materials used, GI tag presence.
3.  **Regressor (XGBoost):** An XGBoost regression model takes the combined features (CLIP embeddings + categorical data + $C_{\text{floor}}$) and predicts the market price.

### Pricing Outputs

*   **$P_{\text{fair}}$ (Fair Price):** The recommended D2C (Direct-to-Consumer) selling price.
*   **$P_{\text{prem}}$ (Premium Price):** $P_{\text{prem}} = 1.20 \times P_{\text{fair}}$. Used for B2B, institutional, or export pricing.

### Training Dataset

The XGBoost model will be trained on a scraped dataset of **45,000+ authentic Indian handicraft listings**:
*   **Sources:** Tribes India, Government e-Marketplace (GeM), Amazon Karigar, ONDC Network data.
*   **Features:** Images, descriptions, materials, and selling prices.
*   **Target Variable:** Actual selling price (filtered for active, successful listings).

---

## System Integration (Flutter App ↔ Backend)

1.  **Frontend Fallback (App-side):** The Flutter app implements the $C_{\text{floor}}$ equation locally in `pricing_corridor.dart` to provide immediate feedback. For the mock/frontend fallback, $P_{\text{fair}}$ is estimated as $1.5 \times C_{\text{floor}}$.
2.  **Backend AI:** In Phase 2, the Kaggle backend will run the XGBoost model on the extracted text and image to return a highly accurate $P_{\text{fair}}$ alongside the $C_{\text{floor}}$.
3.  **Validation:** The Flutter UI strictly enforces `Final Price >= Floor Price`. If an artisan or admin attempts to manually override the price below $C_{\text{floor}}$, the UI blocks the action.
