import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import client from '../../api/client';
import ProductCard from '../../components/ProductCard';
import Navbar from '../../components/Navbar';
import CategoryBar from '../../components/CategoryBar';
import {
    ListBulletIcon,
    MapPinIcon,
    Squares2X2Icon
} from '@heroicons/react/24/outline';
import locationService, { Regency, Province } from '../../services/locationService';

const HomePage = () => {
    const [products, setProducts] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [loadingMore, setLoadingMore] = useState(false);
    const [hasMore, setHasMore] = useState(true);
    const [page, setPage] = useState(0);
    const [searchParams] = useSearchParams();
    const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
    const [sortOrder, setSortOrder] = useState<'newest' | 'price_low' | 'price_high' | 'nearest'>('newest');
    const [selectedLocation, setSelectedLocation] = useState<string>('');
    const [userCoords, setUserCoords] = useState<{ lat: number, lng: number } | null>(null);
    const [regencies, setRegencies] = useState<Regency[]>([]);
    const [provinces, setProvinces] = useState<Province[]>([]);
    const [selectedProvince, setSelectedProvince] = useState<string>('');
    const [loadingLocations, setLoadingLocations] = useState(false);

    const searchQuery = searchParams.get('q');
    const categoryId = searchParams.get('cat');
    const limit = 8; // Small limit for demo purposes

    const loadProducts = async (currentPage: number, isInitial: boolean = false) => {
        if (isInitial) setLoading(true);
        else setLoadingMore(true);

        try {
            let endpoint = `/products?limit=${limit}&offset=${currentPage * limit}`;
            if (searchQuery) {
                endpoint += `&q=${encodeURIComponent(searchQuery)}`;
            } else if (categoryId) {
                endpoint += `&cat=${encodeURIComponent(categoryId)}`;
            }
            if (selectedLocation) {
                endpoint += `&loc=${encodeURIComponent(selectedLocation)}`;
            }

            const res = await client.get(endpoint);
            const allProducts = res.data?.message_data || [];
            // Filter out sold out products for public view
            const newProducts = allProducts.filter((p: any) => (p.stock ?? 0) > 0 && p.status !== 'SOLD');


            if (isInitial) {
                setProducts(newProducts);
            } else {
                setProducts(prev => [...prev, ...newProducts]);
            }

            setHasMore(newProducts.length === limit);
        } catch (err) {
            console.error("Error loading products", err);
            if (isInitial) setProducts([]);
        } finally {
            setLoading(false);
            setLoadingMore(false);
        }
    };

    useEffect(() => {
        setPage(0);
        loadProducts(0, true);
    }, [searchQuery, categoryId, sortOrder, selectedLocation]); // Added selectedLocation

    useEffect(() => {
        loadProvinces();
        loadPopularRegencies().catch(err => {
            console.error('Failed to load popular regencies:', err);
        });
    }, []);

    useEffect(() => {
        if (selectedProvince) {
            loadRegencies(selectedProvince);
        } else {
            loadPopularRegencies();
        }
    }, [selectedProvince]);

    const loadProvinces = async () => {
        try {
            const data = await locationService.getProvinces();
            setProvinces(data);
        } catch (err) {
            console.error('Failed to load provinces', err);
        }
    };

    const loadRegencies = async (provinceCode: string) => {
        setLoadingLocations(true);
        try {
            const data = await locationService.getRegencies(provinceCode);
            setRegencies(data);
        } catch (err) {
            console.error('Failed to load regencies', err);
        } finally {
            setLoadingLocations(false);
        }
    };

    const loadPopularRegencies = async () => {
        setLoadingLocations(true);
        try {
            const popular = await locationService.getPopularRegencies();
            setRegencies(popular);
        } catch (err) {
            console.error('Failed to load popular regencies', err);
            setRegencies([]);
        } finally {
            setLoadingLocations(false);
        }
    };

    const handleLoadMore = () => {
        const nextPage = page + 1;
        setPage(nextPage);
        loadProducts(nextPage, false);
    };

    const handleDetectLocation = () => {
        if (!navigator.geolocation) {
            alert('Geolocation tidak didukung oleh browser Anda');
            return;
        }

        navigator.geolocation.getCurrentPosition(
            (position) => {
                const { latitude, longitude } = position.coords;
                setUserCoords({
                    lat: latitude,
                    lng: longitude
                });
                setSortOrder('nearest');
                alert(`Lokasi terdeteksi! Produk akan diurutkan berdasarkan jarak terdekat.\nKoordinat: ${latitude.toFixed(4)}, ${longitude.toFixed(4)}`);
            },
            (error) => {
                console.error('Geolocation error:', error);
                let errorMessage = 'Gagal mendeteksi lokasi. ';

                switch (error.code) {
                    case error.PERMISSION_DENIED:
                        errorMessage += 'Izin lokasi ditolak. Silakan aktifkan izin lokasi di browser Anda.';
                        break;
                    case error.POSITION_UNAVAILABLE:
                        errorMessage += 'Informasi lokasi tidak tersedia.';
                        break;
                    case error.TIMEOUT:
                        errorMessage += 'Permintaan lokasi timeout.';
                        break;
                    default:
                        errorMessage += 'Terjadi kesalahan yang tidak diketahui.';
                }

                alert(errorMessage);
            },
            {
                enableHighAccuracy: true,
                timeout: 10000,
                maximumAge: 0
            }
        );
    };

    const calculateDistance = (lat1: number, lon1: number, lat2: number, lon2: number) => {
        const R = 6371; // km
        const dLat = (lat2 - lat1) * Math.PI / 180;
        const dLon = (lon2 - lon1) * Math.PI / 180;
        const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    };

    const sortedProducts = [...products].sort((a, b) => {
        // ALWAYS put ACTIVE products at the top, SOLD at the bottom
        if (a.status === 'ACTIVE' && b.status !== 'ACTIVE') return -1;
        if (a.status !== 'ACTIVE' && b.status === 'ACTIVE') return 1;

        // If status is same, apply user sort order
        if (sortOrder === 'nearest' && userCoords) {
            const distA = a.latitude ? calculateDistance(userCoords.lat, userCoords.lng, parseFloat(a.latitude), parseFloat(a.longitude)) : Infinity;
            const distB = b.latitude ? calculateDistance(userCoords.lat, userCoords.lng, parseFloat(b.latitude), parseFloat(b.longitude)) : Infinity;
            return distA - distB;
        }
        if (sortOrder === 'price_low') return a.price - b.price;
        if (sortOrder === 'price_high') return b.price - a.price;
        // newest is default
        return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
    });

    return (
        <div className="min-h-screen bg-gray-50 flex flex-col font-sans text-gray-900">
            <Navbar />
            <CategoryBar />

            <main className="flex-grow max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 w-full py-8 text-left">

                {/* Header Section */}
                <div className="mb-6 sm:mb-8">
                    <div className="flex items-center gap-2 text-[10px] font-bold text-gray-400 mb-3 uppercase tracking-wider">
                        <span>Home</span>
                        <span className="text-gray-300">/</span>
                        <span className="text-rose-500">Marketplace</span>
                    </div>
                    <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-6">
                        <div className="max-w-2xl">
                            <h1 className="text-2xl sm:text-3xl md:text-4xl font-extrabold text-gray-900 tracking-tight leading-tight">
                                {searchQuery ? `Hasil untuk "${searchQuery}"` : 'Rekomendasi Terbaik'}
                            </h1>
                            <p className="text-gray-500 mt-2 text-sm sm:text-base font-medium">
                                Menampilkan {products.length} {products.length === 1 ? 'produk' : 'produk'} {selectedLocation ? `di ${selectedLocation}` : 'di seluruh lokasi'}
                            </p>
                        </div>

                        {/* Top Filters Row (View Mode & Detect Location) - Mobile only shows Detect if no coords */}
                        <div className="flex items-center gap-3 w-full md:w-auto">
                            {!userCoords && (
                                <button
                                    onClick={handleDetectLocation}
                                    className="flex-1 md:flex-none flex items-center justify-center gap-2 px-4 py-3 bg-rose-50 text-rose-600 rounded-xl font-bold text-xs sm:text-sm hover:bg-rose-100 transition-all border border-rose-100 shadow-sm shadow-rose-50"
                                >
                                    <MapPinIcon className="w-4 h-4" />
                                    <span>Aktifkan Lokasi</span>
                                </button>
                            )}
                            <div className="flex items-center bg-white border-2 border-gray-200 rounded-2xl p-1 gap-1 shadow-sm">
                                <button
                                    onClick={() => setViewMode('grid')}
                                    className={`p-2.5 rounded-xl transition-all font-bold text-xs flex items-center gap-1.5 ${viewMode === 'grid'
                                            ? 'bg-gray-900 text-white shadow-md'
                                            : 'text-gray-400 hover:text-gray-700 hover:bg-gray-50'
                                        }`}
                                    title="Grid View"
                                >
                                    <Squares2X2Icon className="w-5 h-5" />
                                    <span className="hidden sm:inline">Grid</span>
                                </button>
                                <button
                                    onClick={() => setViewMode('list')}
                                    className={`p-2.5 rounded-xl transition-all font-bold text-xs flex items-center gap-1.5 ${viewMode === 'list'
                                            ? 'bg-gray-900 text-white shadow-md'
                                            : 'text-gray-400 hover:text-gray-700 hover:bg-gray-50'
                                        }`}
                                    title="List View"
                                >
                                    <ListBulletIcon className="w-5 h-5" />
                                    <span className="hidden sm:inline">List</span>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Filter Controls Bar */}
                <div className="mb-8">
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:flex lg:items-center gap-3">
                        {/* Province Filter */}
                        <div className="relative group">
                            <select
                                value={selectedProvince}
                                onChange={(e) => {
                                    setSelectedProvince(e.target.value);
                                    setSelectedLocation(''); // Reset regency when province changes
                                }}
                                className="w-full lg:w-[200px] appearance-none pl-11 pr-10 py-3.5 bg-white border border-gray-200 rounded-[18px] font-black text-gray-700 hover:border-rose-400 focus:ring-4 focus:ring-rose-500/10 focus:border-rose-500 transition-all text-sm outline-none cursor-pointer shadow-sm group-hover:shadow-md"
                            >
                                <option value="">Semua Provinsi</option>
                                {provinces.map(p => (
                                    <option key={p.code} value={p.code}>{p.name}</option>
                                ))}
                            </select>
                            <MapPinIcon className="w-5 h-5 text-rose-500 absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none" />
                            <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-gray-400 group-hover:text-rose-500 transition-colors">
                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="19 9l-7 7-7-7" /></svg>
                            </div>
                        </div>

                        {/* Location Filter (Regencies) */}
                        <div className="relative group">
                            <select
                                value={selectedLocation}
                                onChange={(e) => setSelectedLocation(e.target.value)}
                                disabled={loadingLocations}
                                className="w-full lg:w-[200px] appearance-none pl-11 pr-10 py-3.5 bg-white border border-gray-200 rounded-[18px] font-black text-gray-700 hover:border-rose-400 focus:ring-4 focus:ring-rose-500/10 focus:border-rose-500 transition-all text-sm outline-none cursor-pointer disabled:opacity-50 shadow-sm group-hover:shadow-md"
                            >
                                <option value="">{selectedProvince ? 'Semua Kota' : 'Kota Populer'}</option>
                                {regencies.map(regency => (
                                    <option key={regency.code} value={regency.name}>{regency.name}</option>
                                ))}
                            </select>
                            <MapPinIcon className="w-5 h-5 text-rose-500 absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none" />
                            <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-gray-400 group-hover:text-rose-500 transition-colors">
                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="19 9l-7 7-7-7" /></svg>
                            </div>
                        </div>

                        {/* Sort Filter */}
                        <div className="relative group lg:ml-auto">
                            <select
                                value={sortOrder}
                                onChange={(e) => setSortOrder(e.target.value as any)}
                                className="w-full lg:w-[180px] appearance-none px-5 py-3.5 bg-gray-900 border border-transparent rounded-[18px] font-black text-white hover:bg-rose-600 focus:ring-4 focus:ring-rose-500/20 transition-all text-sm outline-none cursor-pointer shadow-lg shadow-gray-200"
                            >
                                <option value="newest">Terukan Terbaru</option>
                                <option value="price_low">Harga Terendah</option>
                                <option value="price_high">Harga Tertinggi</option>
                                {userCoords && <option value="nearest">Jarak Terdekat</option>}
                            </select>
                            <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-white/50">
                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="19 9l-7 7-7-7" /></svg>
                            </div>
                        </div>
                    </div>
                </div>

                {loading ? (
                    <div className={viewMode === 'grid' ? "grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-4 gap-6" : "space-y-4"}>
                        {[...Array(8)].map((_, i) => (
                            <div key={i} className={`bg-white rounded-[24px] border border-gray-100 animate-pulse ${viewMode === 'grid' ? 'h-[320px]' : 'h-[120px]'}`}>
                                <div className={viewMode === 'grid' ? "h-2/3 bg-gray-100 rounded-t-[24px]" : "h-full w-1/4 bg-gray-100 rounded-l-[24px]"}></div>
                            </div>
                        ))}
                    </div>
                ) : (
                    <div className={viewMode === 'grid' ? "grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-4 gap-6 pb-12" : "space-y-6 pb-12"}>
                        {sortedProducts.map((p: any) => (
                            <ProductCard key={p.id} product={p} viewMode={viewMode} />
                        ))}
                    </div>
                )}

                {/* Load More Button */}
                {!loading && products.length > 0 && hasMore && (
                    <div className="mt-8 flex justify-center pb-12">
                        <button
                            onClick={handleLoadMore}
                            disabled={loadingMore}
                            className="bg-white border-2 border-gray-900 text-gray-900 font-bold py-3 px-10 rounded-full hover:bg-gray-900 hover:text-white transition-all shadow-sm transform hover:-translate-y-1 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
                        >
                            {loadingMore ? 'Loading...' : 'Load more'}
                        </button>
                    </div>
                )}

                {!loading && products.length === 0 && (
                    <div className="text-center py-20">
                        <div className="text-6xl mb-4">🔍</div>
                        <h3 className="text-xl font-bold text-gray-900">No products found</h3>
                        <p className="text-gray-500 mt-2">Try adjusting your search filters</p>
                    </div>
                )}
            </main>

            {/* Simple Footer */}
            <footer className="bg-white border-t border-gray-100 mt-auto py-10">
                <div className="max-w-7xl mx-auto px-4 text-center">
                    <div className="flex justify-center items-center gap-2 mb-4">
                        <div className="w-8 h-8 bg-gradient-to-br from-pink-500 to-rose-600 rounded-lg flex items-center justify-center text-white font-black text-sm">G</div>
                        <span className="font-bold text-gray-900">GostarMart</span>
                    </div>
                    <div className="text-sm text-gray-500 font-medium">
                        &copy; 2026 Gostar Mart. Designed with ❤️ in Jakarta.
                    </div>
                </div>
            </footer>
        </div>
    );
};

export default HomePage;
