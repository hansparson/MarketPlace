package handler

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	"github.com/user/marketplace-backend/pkg/response"
)

const (
	WilayahBaseURL  = "https://wilayah.web.id/api"
	CacheExpiration = 24 * time.Hour
)

func (h *PublicHandler) GetProvinces(c echo.Context) error {
	cacheKey := "location:provinces"
	ctx := context.Background()

	// Try cache
	val, err := h.Cache.Get(ctx, cacheKey)
	if err == nil {
		var data interface{}
		if unmarshalErr := json.Unmarshal([]byte(val), &data); unmarshalErr == nil {
			return response.Success(c, http.StatusOK, "PROVINCES_FETCHED_FROM_CACHE", data)
		}
	}

	// Fetch from API
	apiURL := fmt.Sprintf("%s/provinces", WilayahBaseURL)
	client := &http.Client{Timeout: 10 * time.Second}
	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return response.Error(c, err)
	}
	req.Header.Set("User-Agent", "Mozilla/5.0")

	resp, err := client.Do(req)
	if err != nil {
		return response.Error(c, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return response.Error(c, fmt.Errorf("API returned status: %d", resp.StatusCode))
	}

	var result struct {
		Data interface{} `json:"data"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return response.Error(c, err)
	}

	// Save to cache
	jsonData, _ := json.Marshal(result.Data)
	h.Cache.Set(ctx, cacheKey, jsonData, CacheExpiration)

	return response.Success(c, http.StatusOK, "PROVINCES_FETCHED", result.Data)
}

func (h *PublicHandler) GetRegencies(c echo.Context) error {
	provinceCode := c.Param("code")
	cacheKey := fmt.Sprintf("location:regencies:%s", provinceCode)
	ctx := context.Background()

	// Try cache
	val, err := h.Cache.Get(ctx, cacheKey)
	if err == nil {
		var data interface{}
		json.Unmarshal([]byte(val), &data)
		return response.Success(c, http.StatusOK, "REGENCIES_FETCHED_FROM_CACHE", data)
	}

	// Fetch from API
	apiURL := fmt.Sprintf("%s/regencies/%s", WilayahBaseURL, provinceCode)
	client := &http.Client{Timeout: 10 * time.Second}
	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return response.Error(c, err)
	}
	req.Header.Set("User-Agent", "Mozilla/5.0")

	resp, err := client.Do(req)
	if err != nil {
		return response.Error(c, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return response.Error(c, fmt.Errorf("API returned status: %d", resp.StatusCode))
	}

	var result struct {
		Data interface{} `json:"data"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return response.Error(c, err)
	}

	// Save to cache
	jsonData, _ := json.Marshal(result.Data)
	h.Cache.Set(ctx, cacheKey, jsonData, CacheExpiration)

	return response.Success(c, http.StatusOK, "REGENCIES_FETCHED", result.Data)
}

func (h *PublicHandler) GetDistricts(c echo.Context) error {
	regencyCode := c.Param("code")
	cacheKey := fmt.Sprintf("location:districts:%s", regencyCode)
	ctx := context.Background()

	// Try cache
	val, err := h.Cache.Get(ctx, cacheKey)
	if err == nil {
		var data interface{}
		json.Unmarshal([]byte(val), &data)
		return response.Success(c, http.StatusOK, "DISTRICTS_FETCHED_FROM_CACHE", data)
	}

	// Fetch from API
	apiURL := fmt.Sprintf("%s/districts/%s", WilayahBaseURL, regencyCode)
	client := &http.Client{Timeout: 10 * time.Second}
	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return response.Error(c, err)
	}
	req.Header.Set("User-Agent", "Mozilla/5.0")

	resp, err := client.Do(req)
	if err != nil {
		return response.Error(c, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return response.Error(c, fmt.Errorf("API returned status: %d", resp.StatusCode))
	}

	var result struct {
		Data interface{} `json:"data"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return response.Error(c, err)
	}

	// Save to cache
	jsonData, _ := json.Marshal(result.Data)
	h.Cache.Set(ctx, cacheKey, jsonData, CacheExpiration)

	return response.Success(c, http.StatusOK, "DISTRICTS_FETCHED", result.Data)
}

func (h *PublicHandler) GetVillages(c echo.Context) error {
	districtCode := c.Param("code")
	cacheKey := fmt.Sprintf("location:villages:%s", districtCode)
	ctx := context.Background()

	// Try cache
	val, err := h.Cache.Get(ctx, cacheKey)
	if err == nil {
		var data interface{}
		json.Unmarshal([]byte(val), &data)
		return response.Success(c, http.StatusOK, "VILLAGES_FETCHED_FROM_CACHE", data)
	}

	// Fetch from API
	apiURL := fmt.Sprintf("%s/villages/%s", WilayahBaseURL, districtCode)
	client := &http.Client{Timeout: 10 * time.Second}
	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return response.Error(c, err)
	}
	req.Header.Set("User-Agent", "Mozilla/5.0")

	resp, err := client.Do(req)
	if err != nil {
		return response.Error(c, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return response.Error(c, fmt.Errorf("API returned status: %d", resp.StatusCode))
	}

	var result struct {
		Data interface{} `json:"data"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return response.Error(c, err)
	}

	// Save to cache
	jsonData, _ := json.Marshal(result.Data)
	h.Cache.Set(ctx, cacheKey, jsonData, CacheExpiration)

	return response.Success(c, http.StatusOK, "VILLAGES_FETCHED", result.Data)
}
