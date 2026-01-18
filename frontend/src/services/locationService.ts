import axios from 'axios';
import { INDONESIA_PROVINCES } from '../data/locations';

const CACHE_DURATION = 24 * 60 * 60 * 1000; // 24 hours in milliseconds

export interface Province {
    code: string;
    name: string;
}

export interface Regency {
    code: string;
    name: string;
    province_code?: string;
}

export interface District {
    code: string;
    name: string;
    regency_code?: string;
}

export interface Village {
    code: string;
    name: string;
    district_code?: string;
    postal_code?: string;
}

class LocationService {
    private getFromCache<T>(key: string): T | null {
        try {
            const item = localStorage.getItem(`location_cache_${key}`);
            if (!item) return null;

            const { data, timestamp } = JSON.parse(item);
            if (Date.now() - timestamp > CACHE_DURATION) {
                localStorage.removeItem(`location_cache_${key}`);
                return null;
            }
            return data;
        } catch (e) {
            return null;
        }
    }

    private setCache(key: string, data: any) {
        try {
            localStorage.setItem(`location_cache_${key}`, JSON.stringify({
                data,
                timestamp: Date.now()
            }));
        } catch (e) {
            console.error('Failed to set cache:', e);
        }
    }

    async getProvinces(): Promise<Province[]> {
        console.log('✅ [locationService] Loading provinces from static data (FAST)');
        return INDONESIA_PROVINCES.map(p => ({
            code: p.id,
            name: p.name
        }));
    }

    async getRegencies(provinceCode: string): Promise<Regency[]> {
        const cacheKey = `regencies_${provinceCode}`;
        const cached = this.getFromCache<Regency[]>(cacheKey);
        if (cached && cached.length > 0) {
            console.log('✅ Regencies loaded from cache:', cached.length);
            return cached;
        } else if (cached) {
            localStorage.removeItem(`location_cache_${cacheKey}`);
        }

        try {
            console.log('🔄 Fetching regencies from proxy:', `/wilayah-api/regencies/${provinceCode}`);
            const response = await axios.get<any>(`/wilayah-api/regencies/${provinceCode}`);
            console.log('📦 Proxy response:', response.data);

            const data = response.data.data || response.data.message_data || [];
            console.log('✅ Regencies fetched:', data.length, 'items');

            if (data.length > 0) {
                this.setCache(cacheKey, data);
            }
            return data;
        } catch (error) {
            console.error('❌ Failed to fetch regencies:', error);
            return [];
        }
    }

    async getDistricts(regencyCode: string): Promise<District[]> {
        const cacheKey = `districts_${regencyCode}`;
        const cached = this.getFromCache<District[]>(cacheKey);
        if (cached && cached.length > 0) {
            console.log('✅ Districts loaded from cache:', cached.length);
            return cached;
        } else if (cached) {
            localStorage.removeItem(`location_cache_${cacheKey}`);
        }

        try {
            console.log('🔄 Fetching districts from proxy:', `/wilayah-api/districts/${regencyCode}`);
            const response = await axios.get<any>(`/wilayah-api/districts/${regencyCode}`);
            console.log('📦 Proxy response:', response.data);

            const data = response.data.data || response.data.message_data || [];
            console.log('✅ Districts fetched:', data.length, 'items');

            if (data.length > 0) {
                this.setCache(cacheKey, data);
            }
            return data;
        } catch (error) {
            console.error('❌ Failed to fetch districts:', error);
            return [];
        }
    }

    async getVillages(districtCode: string): Promise<Village[]> {
        const cacheKey = `villages_${districtCode}`;
        const cached = this.getFromCache<Village[]>(cacheKey);
        if (cached && cached.length > 0) {
            console.log('✅ Villages loaded from cache:', cached.length);
            return cached;
        } else if (cached) {
            localStorage.removeItem(`location_cache_${cacheKey}`);
        }

        try {
            console.log('🔄 Fetching villages from proxy:', `/wilayah-api/villages/${districtCode}`);
            const response = await axios.get<any>(`/wilayah-api/villages/${districtCode}`);
            console.log('📦 Proxy response:', response.data);

            const data = response.data.data || response.data.message_data || [];
            console.log('✅ Villages fetched:', data.length, 'items');

            if (data.length > 0) {
                this.setCache(cacheKey, data);
            }
            return data;
        } catch (error) {
            console.error('❌ Failed to fetch villages:', error);
            return [];
        }
    }

    async getPopularRegencies(): Promise<Regency[]> {
        // Popular province codes for major cities
        const provincesToFetch = ['31', '32', '33', '34', '35', '36', '51', '73'];
        try {
            const results = await Promise.all(
                provincesToFetch.map(code => this.getRegencies(code))
            );
            return results.flat().sort((a, b) => a.name.localeCompare(b.name));
        } catch (error) {
            console.error('Failed to fetch popular regencies:', error);
            return [];
        }
    }

    clearCache() {
        Object.keys(localStorage)
            .filter(key => key.startsWith('location_cache_'))
            .forEach(key => localStorage.removeItem(key));
        console.log('🗑️ Location cache cleared');
    }
}

const locationService = new LocationService();
export default locationService;
