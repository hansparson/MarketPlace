package handler

import (
	"bytes"
	"context"
	"database/sql"
	"fmt"
	"image/jpeg"
	"log"
	"math"
	"mime/multipart"
	"net/http"
	"path/filepath"
	"strconv"
	"time"
	"encoding/json"

	"github.com/disintegration/imaging"
	"github.com/google/uuid"
	"github.com/user/marketplace-backend/internal/database/db"
	"github.com/user/marketplace-backend/pkg/apperrors"
	"github.com/user/marketplace-backend/pkg/response"

	"github.com/labstack/echo/v4"
)

// Add Product
func (h *AdminHandler) CreateProduct(c echo.Context) error {
	var req struct {
		CategoryID               string  `json:"category_id"`
		Title                    string  `json:"title"`
		Description              string  `json:"description"`
		Price                    int64   `json:"price"`
		MemberCommissionAmount   int64   `json:"member_commission_amount"`
		ResellerCommissionAmount int64   `json:"reseller_commission_amount"`
		LocationName             string  `json:"location_name"`
		Latitude                 float64 `json:"latitude"`
		Longitude                float64 `json:"longitude"`
		Province                 string  `json:"province"`
		Regency                  string  `json:"regency"`
		District                 string  `json:"district"`
		Village                  string          `json:"village"`
		Stock                    int32           `json:"stock"`
		Specifications           json.RawMessage `json:"specifications"`
	}

	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	catID, err := uuid.Parse(req.CategoryID)
	if err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	userIDStr, ok := c.Get("user_id").(string)
	if !ok || userIDStr == "" {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	adminID, err := uuid.Parse(userIDStr)
	if err != nil {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	if req.Stock == 0 {
		req.Stock = 1
	}

	specifications := req.Specifications
	if len(specifications) == 0 {
		specifications = []byte("[]")
	}

	product, err := h.Queries.CreateProduct(context.Background(), db.CreateProductParams{
		CategoryID:               catID,
		Title:                    req.Title,
		Description:              req.Description,
		Price:                    req.Price,
		MemberCommissionAmount:   req.MemberCommissionAmount,
		ResellerCommissionAmount: req.ResellerCommissionAmount,
		CommissionAmount:         (req.MemberCommissionAmount + req.ResellerCommissionAmount) / 2,
		CreatedBy:                adminID,
		Status:                   db.ProductStatusACTIVE,
		LocationName:             sql.NullString{String: req.LocationName, Valid: req.LocationName != ""},
		Latitude:                 sql.NullString{String: fmt.Sprintf("%f", req.Latitude), Valid: req.Latitude != 0},
		Longitude:                sql.NullString{String: fmt.Sprintf("%f", req.Longitude), Valid: req.Longitude != 0},
		Province:                 sql.NullString{String: req.Province, Valid: req.Province != ""},
		Regency:                  sql.NullString{String: req.Regency, Valid: req.Regency != ""},
		District:                 sql.NullString{String: req.District, Valid: req.District != ""},
		Village:                  sql.NullString{String: req.Village, Valid: req.Village != ""},
		Stock:                    req.Stock,
		Specifications:           specifications,
	})

	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	if h.Notification != nil {
		go func(p db.Product) {
			ctx := context.Background()
			// Broadcast to gostar-id (MEMBER and RESELLER)
			h.Notification.BroadcastToRoles(ctx, []string{"MEMBER", "RESELLER"}, 
				"Produk Baru Ditambahkan!", 
				fmt.Sprintf("Katalog baru '%s' telah tersedia. Yuk bagikan sekarang dan dapatkan komisinya!", p.Title),
				map[string]string{"type": "new_product", "product_id": p.ID.String()})

			// Broadcast to gostar-mart (CLIENT)
			h.Notification.BroadcastToRoles(ctx, []string{"CLIENT"}, 
				"Produk Baru untuk Anda!", 
				fmt.Sprintf("'%s' kini tersedia di toko. Lihat sekarang!", p.Title),
				map[string]string{"type": "new_product", "product_id": p.ID.String()})
		}(product)
	}

	return response.Success(c, http.StatusCreated, "PRODUCT_CREATED", product)
}

// Upload Asset (supports multiple files)
func (h *AdminHandler) UploadAsset(c echo.Context) error {
	if h.Storage == nil {
		return c.JSON(http.StatusServiceUnavailable, map[string]string{
			"error": "File upload service is currently unavailable.",
		})
	}

	productID := c.FormValue("product_id")
	prodID, err := uuid.Parse(productID)
	if err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	form, err := c.MultipartForm()
	if err != nil {
		log.Printf("[UploadAsset] Failed to parse multipart form: %v", err)
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Failed to parse form: " + err.Error()})
	}

	files := form.File["files"]
	if len(files) == 0 {
		log.Printf("[UploadAsset] No files found in request")
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "No files uploaded"})
	}

	var images, videos []*multipart.FileHeader
	for _, file := range files {
		contentType := file.Header.Get("Content-Type")
		ext := filepath.Ext(file.Filename)

		if contentType == "" {
			if ext == ".jpg" || ext == ".png" || ext == ".jpeg" {
				contentType = "image/jpeg"
			} else if ext == ".mp4" || ext == ".mov" {
				contentType = "video/mp4"
			}
		}

		if len(contentType) >= 5 && contentType[:5] == "image" {
			images = append(images, file)
		} else if len(contentType) >= 5 && contentType[:5] == "video" {
			videos = append(videos, file)
		}
	}

	if len(images) > 5 {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Maximum 5 images allowed"})
	}
	if len(videos) > 2 {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Maximum 2 videos allowed"})
	}

	var uploadedAssets []db.ProductAsset

	for _, file := range images {
		buf, newFilename, err := compressImage(file)
		if err != nil {
			log.Printf("[UploadAsset] Compression failed for %s: %v", file.Filename, err)
			continue // Skip this one but keep going
		}

		var path string
		if buf != nil {
			path, err = h.Storage.UploadStream(context.Background(), buf, int64(buf.Len()), "image/jpeg", newFilename, "products/"+productID)
		} else {
			path, err = h.Storage.UploadFile(context.Background(), file, "products/"+productID)
		}

		if err != nil {
			log.Printf("[UploadAsset] Storage upload failed for %s: %v", file.Filename, err)
			return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to upload to storage: " + err.Error()})
		}

		asset, err := h.Queries.CreateProductAsset(context.Background(), db.CreateProductAssetParams{
			ProductID: prodID,
			AssetType: db.AssetTypeIMAGE,
			ObjectKey: path,
		})
		if err != nil {
			log.Printf("[UploadAsset] DB entry failed for %s: %v", path, err)
			continue
		}
		uploadedAssets = append(uploadedAssets, asset)
	}

	for _, file := range videos {
		path, err := h.Storage.UploadFile(context.Background(), file, "products/"+productID)
		if err != nil {
			log.Printf("[UploadAsset] Video upload failed for %s: %v", file.Filename, err)
			return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to upload video: " + err.Error()})
		}

		asset, err := h.Queries.CreateProductAsset(context.Background(), db.CreateProductAssetParams{
			ProductID: prodID,
			AssetType: db.AssetTypeVIDEO,
			ObjectKey: path,
		})
		if err != nil {
			log.Printf("[UploadAsset] Video DB entry failed for %s: %v", path, err)
			continue
		}
		uploadedAssets = append(uploadedAssets, asset)
	}

	return response.Success(c, http.StatusOK, "ASSETS_UPLOADED", map[string]interface{}{
		"assets": uploadedAssets,
	})
}

// Delete Asset
func (h *AdminHandler) DeleteAsset(c echo.Context) error {
	id := c.Param("id")
	assetID, err := uuid.Parse(id)
	if err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	ctx := context.Background()

	// Fetch asset to get ObjectKey for storage deletion
	asset, err := h.Queries.GetProductAsset(ctx, assetID)
	if err == nil && h.Storage != nil {
		_ = h.Storage.DeleteFile(ctx, asset.ObjectKey)
	}

	err = h.Queries.DeleteProductAsset(ctx, assetID)
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "ASSET_DELETED", nil)
}

// List All Products (for admin)
func (h *AdminHandler) ListAllProducts(c echo.Context) error {
	page, _ := strconv.Atoi(c.QueryParam("page"))
	limit, _ := strconv.Atoi(c.QueryParam("limit"))

	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}

	offset := (page - 1) * limit
	ctx := context.Background()

	totalItems, _ := h.Queries.CountAllProducts(ctx)
	products, _ := h.Queries.AdminListProducts(ctx, db.AdminListProductsParams{
		Limit:  int32(limit),
		Offset: int32(offset),
	})

	totalPages := int(math.Ceil(float64(totalItems) / float64(limit)))

	return response.Success(c, http.StatusOK, "PRODUCTS_LISTED", map[string]interface{}{
		"items": products,
		"pagination": map[string]interface{}{
			"current_page": page,
			"total_pages":  totalPages,
			"total_items":  totalItems,
		},
	})
}

// Get Single Product
func (h *AdminHandler) GetProduct(c echo.Context) error {
	id := c.Param("id")
	productID, err := uuid.Parse(id)
	if err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	product, err := h.Queries.GetProduct(context.Background(), productID)
	if err != nil {
		return response.Error(c, apperrors.ErrNotFound)
	}

	assets, _ := h.Queries.GetProductAssets(context.Background(), productID)

	return response.Success(c, http.StatusOK, "PRODUCT_FOUND", map[string]interface{}{
		"product": product,
		"assets":  assets,
	})
}

// Update Product
func (h *AdminHandler) UpdateProduct(c echo.Context) error {
	id := c.Param("id")
	productID, err := uuid.Parse(id)
	if err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	var req struct {
		CategoryID               string  `json:"category_id"`
		Title                    string  `json:"title"`
		Description              string  `json:"description"`
		Price                    int64   `json:"price"`
		MemberCommissionAmount   int64   `json:"member_commission_amount"`
		ResellerCommissionAmount int64   `json:"reseller_commission_amount"`
		Status                   string  `json:"status"`
		LocationName             string  `json:"location_name"`
		Latitude                 float64 `json:"latitude"`
		Longitude                float64 `json:"longitude"`
		Province                 string  `json:"province"`
		Regency                  string  `json:"regency"`
		District                 string  `json:"district"`
		Village                  string          `json:"village"`
		Stock                    int32           `json:"stock"`
		Specifications           json.RawMessage `json:"specifications"`
	}

	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	catID, _ := uuid.Parse(req.CategoryID)

	specifications := req.Specifications
	if len(specifications) == 0 {
		specifications = []byte("[]")
	}

	product, err := h.Queries.UpdateProduct(context.Background(), db.UpdateProductParams{
		ID:                       productID,
		CategoryID:               catID,
		Title:                    req.Title,
		Description:              req.Description,
		Price:                    req.Price,
		MemberCommissionAmount:   req.MemberCommissionAmount,
		ResellerCommissionAmount: req.ResellerCommissionAmount,
		Status:                   db.ProductStatus(req.Status),
		LocationName:             sql.NullString{String: req.LocationName, Valid: req.LocationName != ""},
		Latitude:                 sql.NullString{String: fmt.Sprintf("%f", req.Latitude), Valid: req.Latitude != 0},
		Longitude:                sql.NullString{String: fmt.Sprintf("%f", req.Longitude), Valid: req.Longitude != 0},
		Province:                 sql.NullString{String: req.Province, Valid: req.Province != ""},
		Regency:                  sql.NullString{String: req.Regency, Valid: req.Regency != ""},
		District:                 sql.NullString{String: req.District, Valid: req.District != ""},
		Village:                  sql.NullString{String: req.Village, Valid: req.Village != ""},
		Stock:                    req.Stock,
		CommissionAmount:         (req.MemberCommissionAmount + req.ResellerCommissionAmount) / 2,
		Specifications:           specifications,
	})

	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "PRODUCT_UPDATED", product)
}

// Delete Product
func (h *AdminHandler) DeleteProduct(c echo.Context) error {
	id := c.Param("id")
	productID, _ := uuid.Parse(id)
	ctx := context.Background()

	// Delete assets from storage first
	assets, err := h.Queries.GetProductAssets(ctx, productID)
	if err == nil && h.Storage != nil {
		for _, asset := range assets {
			_ = h.Storage.DeleteFile(ctx, asset.ObjectKey)
		}
	}

	h.Queries.DeleteProductAssets(ctx, productID)
	err = h.Queries.DeleteProduct(ctx, productID)
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "PRODUCT_DELETED", nil)
}

// Get Product Leads
func (h *AdminHandler) GetProductLeads(c echo.Context) error {
	id := c.Param("id")
	productID, _ := uuid.Parse(id)

	leads, err := h.Queries.GetLeadsByProduct(context.Background(), productID)
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "PRODUCT_LEADS_RETRIEVED", leads)
}

// List Mart Clients
func (h *AdminHandler) ListMartClients(c echo.Context) error {
	search := c.QueryParam("q")

	clients, err := h.Queries.ListMartClients(context.Background(), search)
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "MART_CLIENTS_RETRIEVED", clients)
}

// Mark Product as Sold
func (h *AdminHandler) MarkProductSold(c echo.Context) error {
	id := c.Param("id")
	productID, _ := uuid.Parse(id)

	var req struct {
		LeadID       string `json:"lead_id"`
		MartClientID string `json:"mart_client_id"`
		UnitsSold    int32  `json:"units_sold"`
	}
	c.Bind(&req)

	if req.UnitsSold <= 0 {
		return response.Error(c, echo.NewHTTPError(http.StatusBadRequest, "units_sold must be > 0"))
	}

	log.Printf("[MarkProductSold] productID: %s, leadID: %s, martClientID: %s, unitsSold: %d", id, req.LeadID, req.MartClientID, req.UnitsSold)

	ctx := context.Background()
	var tx *sql.Tx
	var q db.Querier = h.Queries
	var err error

	if h.DB != nil {
		tx, err = h.DB.BeginTx(ctx, nil)
		if err != nil {
			return response.Error(c, apperrors.ErrInternalServerError)
		}
		defer tx.Rollback()
		q = db.New(tx)
	}

	product, err := q.GetProduct(ctx, productID)
	if err != nil {
		return response.Error(c, echo.NewHTTPError(http.StatusBadRequest, "Product not found"))
	}
	if product.Stock < req.UnitsSold {
		return response.Error(c, echo.NewHTTPError(http.StatusBadRequest, "Not enough stock"))
	}

	newStock := product.Stock - req.UnitsSold
	newStatus := product.Status
	if newStock <= 0 {
		newStatus = db.ProductStatusSOLD
		newStock = 0
	}

	if req.LeadID != "" {
		leadID, err := uuid.Parse(req.LeadID)
		if err != nil {
			log.Printf("[MarkProductSold] Failed to parse leadID: %v", err)
		} else {
			leads, err := q.GetLeadsByProduct(ctx, productID)
			if err != nil {
				log.Printf("[MarkProductSold] Failed to fetch leads: %v", err)
			}
			
			foundLead := false
			for _, l := range leads {
				if l.ID == leadID {
					foundLead = true
					if l.Status == db.LeadStatusDEAL {
						return response.Error(c, echo.NewHTTPError(http.StatusBadRequest, "Lead already processed"))
					}

					log.Printf("[MarkProductSold] Found lead for reseller: %s (ID: %v)", l.ResellerName, l.ResellerID)
					
					err = q.UpdateLeadStatus(ctx, db.UpdateLeadStatusParams{
						ID:     leadID,
						Status: db.LeadStatusDEAL,
					})
					if err != nil {
						log.Printf("[MarkProductSold] Failed to update lead status: %v", err)
					}

					// 1. Create Reseller Commission (ONLY if reseller_id is present)
					if l.ResellerID.Valid && product.ResellerCommissionAmount > 0 {
						comm, err := q.CreateCommission(ctx, db.CreateCommissionParams{
							UserID:       l.ResellerID,
							ProductID:    uuid.NullUUID{UUID: productID, Valid: true},
							Amount:       product.ResellerCommissionAmount * int64(req.UnitsSold),
							Status:       "PENDING",
							UserType:     "RESELLER",
							ReferralCode: sql.NullString{String: l.ReferralCode, Valid: true},
						})
						if err != nil {
							log.Printf("[MarkProductSold] Error creating reseller commission: %v", err)
						} else {
							log.Printf("[MarkProductSold] Created reseller commission: %d (ID: %s)", comm.Amount, comm.ID)
							if h.Notification != nil {
								h.Notification.NotifyUser(ctx, l.ResellerID.UUID, "RESELLER",
									"Komisi Baru Masuk!",
									fmt.Sprintf("Produk '%s' terjual! Anda mendapatkan komisi sebesar Rp %d.", product.Title, comm.Amount),
									map[string]string{"type": "commission", "amount": fmt.Sprintf("%d", comm.Amount)})
							}
						}
					}

					// 2. Create Member Commission
					if product.MemberCommissionAmount > 0 {
						var memberID uuid.NullUUID
						if l.ResellerID.Valid {
							// For Reseller lead, find their leader (member)
							reseller, err := q.GetReseller(ctx, l.ResellerID.UUID)
							if err == nil && reseller.MemberID.Valid {
								memberID = reseller.MemberID
							}
						} else if l.MemberID.Valid {
							// Direct Member lead
							memberID = l.MemberID
						}

						if memberID.Valid {
							comm, err := q.CreateCommission(ctx, db.CreateCommissionParams{
								UserID:       memberID,
								ProductID:    uuid.NullUUID{UUID: productID, Valid: true},
								Amount:       product.MemberCommissionAmount * int64(req.UnitsSold),
								Status:       "PENDING",
								UserType:     "MEMBER",
								ReferralCode: sql.NullString{String: l.ReferralCode, Valid: true},
							})
							if err != nil {
								log.Printf("[MarkProductSold] Error creating member commission: %v", err)
							} else {
								log.Printf("[MarkProductSold] Created member commission: %d (ID: %s)", comm.Amount, comm.ID)
								if h.Notification != nil {
									h.Notification.NotifyUser(ctx, memberID.UUID, "MEMBER",
										"Komisi Referral Baru!",
										fmt.Sprintf("Produk '%s' terjual! Anda mendapatkan komisi sebesar Rp %d.", product.Title, comm.Amount),
										map[string]string{"type": "commission", "amount": fmt.Sprintf("%d", comm.Amount)})
								}
							}
						}
					}
					break
				}
			}
			if !foundLead {
				log.Printf("[MarkProductSold] Lead ID %s not found in leads for product %s", req.LeadID, id)
			}
		}
	} else if req.MartClientID != "" {
		clientID, err := uuid.Parse(req.MartClientID)
		if err != nil {
			log.Printf("[MarkProductSold] Failed to parse martClientID: %v", err)
		} else {
			client, err := q.GetMartClientByID(ctx, clientID)
			if err != nil {
				log.Printf("[MarkProductSold] Failed to fetch mart client: %v", err)
			} else {
				// Notify Client of successful purchase (gostar-mart)
				if h.Notification != nil {
					h.Notification.NotifyUser(ctx, clientID, "CLIENT",
						"Pembelian Berhasil!",
						fmt.Sprintf("Produk '%s' telah terjual atas nama Anda.", product.Title),
						map[string]string{"type": "purchase_success", "product_id": product.ID.String()})
				}

				if client.ReferralCodeUsed.Valid && client.ReferralCodeUsed.String != "" {
					refCode := client.ReferralCodeUsed.String
					refInfo, err := q.CheckReferralCodeExists(ctx, refCode)
					if err != nil {
						log.Printf("[MarkProductSold] Failed to check referral code: %v", err)
					} else if refInfo.IsExists {
						log.Printf("[MarkProductSold] Found referrer for client: %s (Type: %s, ID: %s)", refCode, refInfo.UserType, refInfo.ReferrerID)
						
						if refInfo.UserType == "RESELLER" && product.ResellerCommissionAmount > 0 {
							comm, err := q.CreateCommission(ctx, db.CreateCommissionParams{
								UserID:       uuid.NullUUID{UUID: refInfo.ReferrerID, Valid: true},
								ProductID:    uuid.NullUUID{UUID: productID, Valid: true},
								Amount:       product.ResellerCommissionAmount * int64(req.UnitsSold),
								Status:       "PENDING",
								UserType:     "RESELLER",
								ReferralCode: sql.NullString{String: refCode, Valid: true},
							})
							if err != nil {
								log.Printf("[MarkProductSold] Error creating reseller commission: %v", err)
							} else {
								if h.Notification != nil {
									h.Notification.NotifyUser(ctx, refInfo.ReferrerID, "RESELLER",
										"Komisi Baru Masuk!",
										fmt.Sprintf("Produk '%s' terjual! Anda mendapatkan komisi sebesar Rp %d.", product.Title, comm.Amount),
										map[string]string{"type": "commission", "amount": fmt.Sprintf("%d", comm.Amount)})
								}
							}
							
							if product.MemberCommissionAmount > 0 {
								reseller, err := q.GetReseller(ctx, refInfo.ReferrerID)
								if err == nil && reseller.MemberID.Valid {
									comm, err := q.CreateCommission(ctx, db.CreateCommissionParams{
										UserID:       reseller.MemberID,
										ProductID:    uuid.NullUUID{UUID: productID, Valid: true},
										Amount:       product.MemberCommissionAmount * int64(req.UnitsSold),
										Status:       "PENDING",
										UserType:     "MEMBER",
										ReferralCode: sql.NullString{String: refCode, Valid: true},
									})
									if err != nil {
										log.Printf("[MarkProductSold] Error creating member commission: %v", err)
									} else {
										if h.Notification != nil {
											h.Notification.NotifyUser(ctx, reseller.MemberID.UUID, "MEMBER",
												"Komisi Referral Baru!",
												fmt.Sprintf("Produk '%s' terjual! Anda mendapatkan komisi sebesar Rp %d.", product.Title, comm.Amount),
												map[string]string{"type": "commission", "amount": fmt.Sprintf("%d", comm.Amount)})
										}
									}
								}
							}
						} else if refInfo.UserType == "MEMBER" && product.MemberCommissionAmount > 0 {
							comm, err := q.CreateCommission(ctx, db.CreateCommissionParams{
								UserID:       uuid.NullUUID{UUID: refInfo.ReferrerID, Valid: true},
								ProductID:    uuid.NullUUID{UUID: productID, Valid: true},
								Amount:       product.MemberCommissionAmount * int64(req.UnitsSold),
								Status:       "PENDING",
								UserType:     "MEMBER",
								ReferralCode: sql.NullString{String: refCode, Valid: true},
							})
							if err != nil {
								log.Printf("[MarkProductSold] Error creating member commission: %v", err)
							} else {
								if h.Notification != nil {
									h.Notification.NotifyUser(ctx, refInfo.ReferrerID, "MEMBER",
										"Komisi Referral Baru!",
										fmt.Sprintf("Produk '%s' terjual! Anda mendapatkan komisi sebesar Rp %d.", product.Title, comm.Amount),
										map[string]string{"type": "commission", "amount": fmt.Sprintf("%d", comm.Amount)})
								}
							}
						}
					}
				}
			}
		}
	} else {
		log.Printf("[MarkProductSold] No LeadID or MartClientID provided, skipping commission allocation.")
	}

	q.UpdateProduct(ctx, db.UpdateProductParams{
		ID:                       productID,
		CategoryID:               product.CategoryID,
		Title:                    product.Title,
		Description:              product.Description,
		Price:                    product.Price,
		MemberCommissionAmount:   product.MemberCommissionAmount,
		ResellerCommissionAmount: product.ResellerCommissionAmount,
		Status:                   newStatus,
		LocationName:             product.LocationName,
		Latitude:                 product.Latitude,
		Longitude:                 product.Longitude,
		Province:                 product.Province,
		Regency:                  product.Regency,
		District:                 product.District,
		Village:                  product.Village,
		Stock:                    newStock,
		CommissionAmount:         product.CommissionAmount,
	})

	if tx != nil {
		if err := tx.Commit(); err != nil {
			return response.Error(c, apperrors.ErrInternalServerError)
		}
	}

	return response.Success(c, http.StatusOK, "PRODUCT_UPDATED", nil)
}

// Helper to compress image
func compressImage(file *multipart.FileHeader) (*bytes.Buffer, string, error) {
	src, err := file.Open()
	if err != nil {
		return nil, "", err
	}
	defer src.Close()

	img, err := imaging.Decode(src)
	if err != nil {
		return nil, "", err
	}

	if img.Bounds().Dx() > 1000 {
		img = imaging.Resize(img, 1000, 0, imaging.Lanczos)
	}

	buf := new(bytes.Buffer)
	err = jpeg.Encode(buf, img, &jpeg.Options{Quality: 80})
	if err != nil {
		return nil, "", err
	}

	ext := filepath.Ext(file.Filename)
	name := file.Filename[0 : len(file.Filename)-len(ext)]
	// Add timestamp to ensure uniqueness
	newFilename := fmt.Sprintf("%s_%d.jpg", name, time.Now().UnixNano())

	return buf, newFilename, nil
}
