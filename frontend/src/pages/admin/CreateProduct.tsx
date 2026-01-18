import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeftIcon, PhotoIcon, VideoCameraIcon, XMarkIcon, MapPinIcon } from '@heroicons/react/24/outline';
import client from '../api/client';
import locationService, { Province, Regency, District, Village } from '../services/locationService';

const CreateProduct = () => {
    const navigate = useNavigate();
    const [categories, setCategories] = useState<any[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [formData, setFormData] = useState({
        category_id: '',
        title: '',
        description: '',
        price: '',
        commission_amount: '',
        stock: '1', // Default stock 1
        location_name: '',
        latitude: 0 as number,
        longitude: 0 as number,
        province: '',
        regency: '',
        district: '',
        village: '',
    });
    const [imageFiles, setImageFiles] = useState<File[]>([]);
    const [videoFiles, setVideoFiles] = useState<File[]>([]);
    const [imagePreviews, setImagePreviews] = useState<string[]>([]);
    const [videoPreviews, setVideoPreviews] = useState<string[]>([]);

    // Location states
    const [provinces, setProvinces] = useState<Province[]>([]);
    const [regencies, setRegencies] = useState<Regency[]>([]);
    const [districts, setDistricts] = useState<District[]>([]);
    const [villages, setVillages] = useState<Village[]>([]);
    const [selectedProvince, setSelectedProvince] = useState<string>('');
    const [selectedRegency, setSelectedRegency] = useState<string>('');
    const [selectedDistrict, setSelectedDistrict] = useState<string>('');
    const [selectedVillage, setSelectedVillage] = useState<string>('');
    const [loadingLocations, setLoadingLocations] = useState(false);
    const [detectingLocation, setDetectingLocation] = useState(false); // New state for GPS button

    useEffect(() => {
        console.log('🚀 [CreateProduct] Component mounted');
        const token = localStorage.getItem('token');
        if (!token) {
            console.log('⚠️ [CreateProduct] No token, redirecting to login');
            navigate('/auth/login/admin');
            return;
        }
        console.log('✅ [CreateProduct] Token found, loading data...');
        loadCategories();
        loadProvinces();
        // REMOVED auto detect location on mount to avoid stuck "Creating..." button
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []); // Empty deps - only run once on mount

    useEffect(() => {
        if (selectedProvince) {
            loadRegencies(selectedProvince);
        }
    }, [selectedProvince]);

    useEffect(() => {
        if (selectedRegency) {
            loadDistricts(selectedRegency);
        }
    }, [selectedRegency]);

    useEffect(() => {
        if (selectedDistrict) {
            loadVillages(selectedDistrict);
        }
    }, [selectedDistrict]);

    // Debug: Monitor provinces state changes
    useEffect(() => {
        console.log('📊 [CreateProduct] Provinces state changed:', provinces.length, 'items');
        if (provinces.length > 0) {
            console.log('📋 [CreateProduct] Sample provinces:', provinces.slice(0, 3));
        }
    }, [provinces]);

    const loadCategories = async () => {
        try {
            const res = await client.get('/categories');
            if (res.data && res.data.message_data) {
                setCategories(res.data.message_data);
            }
        } catch (err) {
            console.error('Failed to load categories', err);
        }
    };

    const loadProvinces = async () => {
        console.log('🔄 [CreateProduct] Starting loadProvinces...');
        setLoadingLocations(true);
        try {
            const data = await locationService.getProvinces();
            console.log('✅ [CreateProduct] Provinces received:', data.length, 'items');
            console.log('📋 [CreateProduct] First 3 provinces:', data.slice(0, 3));
            setProvinces(data);
            console.log('✅ [CreateProduct] Provinces state updated');
        } catch (err) {
            console.error('❌ [CreateProduct] Failed to load provinces:', err);
        } finally {
            setLoadingLocations(false);
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

    const loadDistricts = async (regencyCode: string) => {
        setLoadingLocations(true);
        try {
            const data = await locationService.getDistricts(regencyCode);
            setDistricts(data);
        } catch (err) {
            console.error('Failed to load districts', err);
        } finally {
            setLoadingLocations(false);
        }
    };

    const loadVillages = async (districtCode: string) => {
        setLoadingLocations(true);
        try {
            const data = await locationService.getVillages(districtCode);
            setVillages(data);
        } catch (err) {
            console.error('Failed to load villages', err);
        } finally {
            setLoadingLocations(false);
        }
    };

    const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const files = Array.from(e.target.files || []);

        if (imageFiles.length + files.length > 5) {
            setError('Maximum 5 images allowed');
            return;
        }

        const newImages = [...imageFiles, ...files];
        setImageFiles(newImages);

        // Generate previews
        const newPreviews = [...imagePreviews];
        files.forEach(file => {
            const reader = new FileReader();
            reader.onloadend = () => {
                newPreviews.push(reader.result as string);
                setImagePreviews([...newPreviews]);
            };
            reader.readAsDataURL(file);
        });
    };

    const handleVideoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const files = Array.from(e.target.files || []);

        if (videoFiles.length + files.length > 2) {
            setError('Maximum 2 videos allowed');
            return;
        }

        const newVideos = [...videoFiles, ...files];
        setVideoFiles(newVideos);

        // Generate previews
        const newPreviews = [...videoPreviews];
        files.forEach(file => {
            const reader = new FileReader();
            reader.onloadend = () => {
                newPreviews.push(reader.result as string);
                setVideoPreviews([...newPreviews]);
            };
            reader.readAsDataURL(file);
        });
    };

    const handleDetectLocation = () => {
        if (!navigator.geolocation) {
            setError('Geolocation is not supported by your browser');
            return;
        }

        setDetectingLocation(true);
        navigator.geolocation.getCurrentPosition(
            (position) => {
                const { latitude, longitude } = position.coords;
                // Simple reverse look up mock (real app would use API)
                setFormData(prev => ({
                    ...prev,
                    latitude,
                    longitude,
                    location_name: prev.location_name || 'My Current Location'
                }));
                setDetectingLocation(false);
            },
            (err) => {
                console.error('Geolocation error', err);
                setError('Failed to get your location. Please select manually.');
                setDetectingLocation(false);
            }
        );
    };

    const handleProvinceChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
        const provinceCode = e.target.value;
        setSelectedProvince(provinceCode);
        setSelectedRegency('');
        setSelectedDistrict('');
        setSelectedVillage('');
        setRegencies([]);
        setDistricts([]);
        setVillages([]);

        const province = provinces.find(p => p.code === provinceCode);
        if (province) {
            setFormData({
                ...formData,
                location_name: province.name,
                latitude: 0,
                longitude: 0,
                province: province.name,
                regency: '',
                district: '',
                village: ''
            });
        }
    };

    const handleRegencyChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
        const regencyCode = e.target.value;
        setSelectedRegency(regencyCode);
        setSelectedDistrict('');
        setSelectedVillage('');
        setDistricts([]);
        setVillages([]);

        const regency = regencies.find(r => r.code === regencyCode);
        const province = provinces.find(p => p.code === selectedProvince);

        if (regency && province) {
            const locationName = `${regency.name}, ${province.name}`;
            setFormData({
                ...formData,
                location_name: locationName,
                latitude: 0,
                longitude: 0,
                province: province.name,
                regency: regency.name,
                district: '',
                village: ''
            });
        }
    };

    const handleDistrictChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
        const districtCode = e.target.value;
        setSelectedDistrict(districtCode);
        setSelectedVillage('');
        setVillages([]);

        const district = districts.find(d => d.code === districtCode);
        const regency = regencies.find(r => r.code === selectedRegency);
        const province = provinces.find(p => p.code === selectedProvince);

        if (district && regency && province) {
            const locationName = `${district.name}, ${regency.name}, ${province.name}`;
            setFormData({
                ...formData,
                location_name: locationName,
                latitude: 0,
                longitude: 0,
                province: province.name,
                regency: regency.name,
                district: district.name,
                village: ''
            });
        }
    };

    const handleVillageChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
        const villageCode = e.target.value;
        setSelectedVillage(villageCode);

        const village = villages.find(v => v.code === villageCode);
        const district = districts.find(d => d.code === selectedDistrict);
        const regency = regencies.find(r => r.code === selectedRegency);
        const province = provinces.find(p => p.code === selectedProvince);

        if (village && district && regency && province) {
            const locationName = `${village.name}, ${district.name}, ${regency.name}, ${province.name}`;
            setFormData({
                ...formData,
                location_name: locationName,
                latitude: 0,
                longitude: 0,
                province: province.name,
                regency: regency.name,
                district: district.name,
                village: village.name
            });
        }
    };

    const removeImage = (index: number) => {
        setImageFiles(imageFiles.filter((_, i) => i !== index));
        setImagePreviews(imagePreviews.filter((_, i) => i !== index));
    };

    const removeVideo = (index: number) => {
        setVideoFiles(videoFiles.filter((_, i) => i !== index));
        setVideoPreviews(videoPreviews.filter((_, i) => i !== index));
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');

        if (imageFiles.length < 1) {
            setError('At least 1 image is required');
            return;
        }

        setLoading(true);

        try {
            const token = localStorage.getItem('token');

            // Step 1: Create product
            const productRes = await client.post('/admin/products', {
                ...formData,
                price: parseInt(formData.price),
                commission_amount: parseInt(formData.commission_amount || '0'),
                stock: parseInt(formData.stock || '1')
            }, {
                headers: { Authorization: `Bearer ${token}` }
            });

            if (productRes.data && productRes.data.message_data) {
                const productId = productRes.data.message_data.id;

                // Step 2: Upload files if exists
                if (imageFiles.length > 0 || videoFiles.length > 0) {
                    const formDataFiles = new FormData();
                    formDataFiles.append('product_id', productId);

                    // Add all images
                    imageFiles.forEach(file => {
                        formDataFiles.append('files', file);
                    });

                    // Add all videos
                    videoFiles.forEach(file => {
                        formDataFiles.append('files', file);
                    });

                    await client.post('/admin/products/assets', formDataFiles, {
                        headers: {
                            Authorization: `Bearer ${token}`,
                            'Content-Type': 'multipart/form-data'
                        }
                    });
                }

                alert('Product created successfully!');
                navigate('/admin/dashboard');
            }
        } catch (err: any) {
            console.error('Failed to create product', err);
            setError(err.response?.data?.message_data || err.response?.data?.error || 'Failed to create product');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
            <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                {/* Header */}
                <div className="mb-8">
                    <button
                        onClick={() => navigate('/admin/dashboard')}
                        className="flex items-center gap-2 text-gray-600 hover:text-gray-900 mb-4 transition-colors"
                    >
                        <ArrowLeftIcon className="w-5 h-5" />
                        Back to Dashboard
                    </button>
                    <h1 className="text-3xl font-bold text-gray-900">Create New Product (V2)</h1>
                    <p className="text-gray-500 mt-1">Add a new product to your marketplace</p>
                </div>

                {/* Form */}
                <form onSubmit={handleSubmit} className="bg-white rounded-2xl shadow-lg border border-gray-100 overflow-hidden">
                    <div className="p-6 space-y-6">
                        {/* Images Upload */}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                Product Images * (1-5 images)
                            </label>
                            <div className="grid grid-cols-5 gap-4 mb-4">
                                {imagePreviews.map((preview, index) => (
                                    <div key={index} className="relative aspect-square rounded-lg overflow-hidden border-2 border-gray-200">
                                        <img src={preview} alt={`Preview ${index + 1}`} className="w-full h-full object-cover" />
                                        <button
                                            type="button"
                                            onClick={() => removeImage(index)}
                                            className="absolute top-1 right-1 bg-red-500 text-white rounded-full p-1 hover:bg-red-600"
                                        >
                                            <XMarkIcon className="w-4 h-4" />
                                        </button>
                                        {index === 0 && (
                                            <div className="absolute bottom-0 left-0 right-0 bg-blue-500 text-white text-xs py-1 text-center">
                                                Main
                                            </div>
                                        )}
                                    </div>
                                ))}
                                {imageFiles.length < 5 && (
                                    <label className="aspect-square flex flex-col items-center justify-center border-2 border-dashed border-gray-300 rounded-lg cursor-pointer hover:border-blue-500 transition-colors">
                                        <PhotoIcon className="w-8 h-8 text-gray-400" />
                                        <span className="text-xs text-gray-500 mt-2">Add Image</span>
                                        <input
                                            type="file"
                                            accept="image/*"
                                            multiple
                                            onChange={handleImageChange}
                                            className="hidden"
                                        />
                                    </label>
                                )}
                            </div>
                            <p className="text-xs text-gray-500">
                                {imageFiles.length}/5 images • First image will be the main product image
                            </p>
                        </div>

                        {/* Videos Upload */}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                Product Videos (Optional, max 2)
                            </label>
                            <div className="grid grid-cols-2 gap-4 mb-4">
                                {videoPreviews.map((preview, index) => (
                                    <div key={index} className="relative aspect-video rounded-lg overflow-hidden border-2 border-gray-200">
                                        <video src={preview} className="w-full h-full object-cover" />
                                        <button
                                            type="button"
                                            onClick={() => removeVideo(index)}
                                            className="absolute top-2 right-2 bg-red-500 text-white rounded-full p-1 hover:bg-red-600"
                                        >
                                            <XMarkIcon className="w-4 h-4" />
                                        </button>
                                    </div>
                                ))}
                                {videoFiles.length < 2 && (
                                    <label className="aspect-video flex flex-col items-center justify-center border-2 border-dashed border-gray-300 rounded-lg cursor-pointer hover:border-blue-500 transition-colors">
                                        <VideoCameraIcon className="w-8 h-8 text-gray-400" />
                                        <span className="text-xs text-gray-500 mt-2">Add Video</span>
                                        <input
                                            type="file"
                                            accept="video/*"
                                            multiple
                                            onChange={handleVideoChange}
                                            className="hidden"
                                        />
                                    </label>
                                )}
                            </div>
                            <p className="text-xs text-gray-500">{videoFiles.length}/2 videos</p>
                        </div>

                        {/* Category */}
                        <div>
                            <label htmlFor="category" className="block text-sm font-medium text-gray-700 mb-2">
                                Category *
                            </label>
                            <select
                                id="category"
                                required
                                value={formData.category_id}
                                onChange={(e) => setFormData({ ...formData, category_id: e.target.value })}
                                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                            >
                                <option value="">Select a category</option>
                                {categories.map((cat) => (
                                    <option key={cat.id} value={cat.id}>{cat.name}</option>
                                ))}
                            </select>
                        </div>

                        {/* Title */}
                        <div>
                            <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-2">
                                Product Title *
                            </label>
                            <input
                                id="title"
                                type="text"
                                required
                                value={formData.title}
                                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                                placeholder="e.g., iPhone 15 Pro Max 256GB"
                                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                            />
                        </div>

                        {/* Description */}
                        <div>
                            <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-2">
                                Description *
                            </label>
                            <textarea
                                id="description"
                                required
                                rows={4}
                                value={formData.description}
                                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                placeholder="Describe your product in detail..."
                                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all resize-none"
                            />
                        </div>

                        {/* Price */}
                        <div>
                            <label htmlFor="price" className="block text-sm font-medium text-gray-700 mb-2">
                                Price (IDR) *
                            </label>
                            <div className="relative">
                                <span className="absolute left-4 top-3 text-gray-500">Rp</span>
                                <input
                                    id="price"
                                    type="number"
                                    required
                                    min="0"
                                    value={formData.price}
                                    onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                                    placeholder="0"
                                    className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                                />
                            </div>
                        </div>

                        {/* Commission */}
                        <div>
                            <label htmlFor="commission" className="block text-sm font-medium text-gray-700 mb-2">
                                Reseller Commission (IDR) *
                            </label>
                            <div className="relative">
                                <span className="absolute left-4 top-3 text-gray-500">Rp</span>
                                <input
                                    id="commission"
                                    type="number"
                                    required
                                    min="0"
                                    value={formData.commission_amount}
                                    onChange={(e) => setFormData({ ...formData, commission_amount: e.target.value })}
                                    placeholder="0"
                                    className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                                />
                                <p className="mt-1 text-xs text-gray-500">Amount to be given to reseller when this product is sold through their link.</p>
                            </div>
                        </div>

                        {/* Stock */}
                        <div>
                            <label htmlFor="stock" className="block text-sm font-medium text-gray-700 mb-2">
                                Stock / Jumlah Stok *
                            </label>
                            <input
                                id="stock"
                                type="number"
                                required
                                min="0"
                                value={formData.stock}
                                onChange={(e) => setFormData({ ...formData, stock: e.target.value })}
                                placeholder="1"
                                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                            />
                            <p className="mt-1 text-xs text-gray-500">
                                {formData.stock === '0' ? (
                                    <span className="text-red-600 font-medium">⚠️ Stok habis - produk tidak akan muncul di marketplace</span>
                                ) : (
                                    <span className="text-green-600">✓ {formData.stock} unit tersedia</span>
                                )}
                            </p>
                        </div>

                        {/* Location */}
                        <div className="pt-4 border-t border-gray-100">
                            <label className="block text-sm font-bold text-gray-900 mb-4 flex items-center gap-2">
                                <MapPinIcon className="w-5 h-5 text-rose-500" />
                                Product Location *
                            </label>
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-xs font-semibold text-gray-500 uppercase tracking-widest mb-1.5 ml-1">Provinsi</label>
                                    <select
                                        value={selectedProvince}
                                        onChange={handleProvinceChange}
                                        disabled={loadingLocations}
                                        className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 transition-all outline-none disabled:opacity-50"
                                    >
                                        <option value="">Pilih Provinsi</option>
                                        {provinces.length === 0 && (
                                            <option disabled>Loading provinces...</option>
                                        )}
                                        {provinces.map(province => (
                                            <option key={province.code} value={province.code}>{province.name}</option>
                                        ))}
                                    </select>
                                </div>

                                <div>
                                    <label className="block text-xs font-semibold text-gray-500 uppercase tracking-widest mb-1.5 ml-1">Kabupaten/Kota</label>
                                    <select
                                        value={selectedRegency}
                                        onChange={handleRegencyChange}
                                        disabled={!selectedProvince || loadingLocations}
                                        className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 transition-all outline-none disabled:opacity-50"
                                    >
                                        <option value="">Pilih Kabupaten/Kota</option>
                                        {regencies.map(regency => (
                                            <option key={regency.code} value={regency.code}>{regency.name}</option>
                                        ))}
                                    </select>
                                </div>

                                <div>
                                    <label className="block text-xs font-semibold text-gray-500 uppercase tracking-widest mb-1.5 ml-1">Kecamatan</label>
                                    <select
                                        value={selectedDistrict}
                                        onChange={handleDistrictChange}
                                        disabled={!selectedRegency || loadingLocations}
                                        className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 transition-all outline-none disabled:opacity-50"
                                    >
                                        <option value="">Pilih Kecamatan</option>
                                        {districts.map(district => (
                                            <option key={district.code} value={district.code}>{district.name}</option>
                                        ))}
                                    </select>
                                </div>

                                <div>
                                    <label className="block text-xs font-semibold text-gray-500 uppercase tracking-widest mb-1.5 ml-1">Desa/Kelurahan</label>
                                    <select
                                        value={selectedVillage}
                                        onChange={handleVillageChange}
                                        disabled={!selectedDistrict || loadingLocations}
                                        className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 transition-all outline-none disabled:opacity-50"
                                    >
                                        <option value="">Pilih Desa/Kelurahan</option>
                                        {villages.map(village => (
                                            <option key={village.code} value={village.code}>{village.name}</option>
                                        ))}
                                    </select>
                                </div>
                            </div>

                            <div className="mt-4">
                                <label className="block text-xs font-semibold text-gray-500 uppercase tracking-widest mb-1.5 ml-1">Manual Entry / GPS</label>
                                <div className="flex gap-2">
                                    <input
                                        type="text"
                                        value={formData.location_name}
                                        onChange={(e) => setFormData({ ...formData, location_name: e.target.value })}
                                        placeholder="Atau ketik manual..."
                                        className="flex-1 px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 transition-all outline-none"
                                    />
                                    <button
                                        type="button"
                                        onClick={handleDetectLocation}
                                        disabled={detectingLocation}
                                        title="Detect my location"
                                        className="px-4 py-3 bg-rose-50 text-rose-600 rounded-xl hover:bg-rose-100 transition-colors disabled:opacity-50"
                                    >
                                        {detectingLocation ? (
                                            <div className="w-5 h-5 border-2 border-rose-600 border-t-transparent rounded-full animate-spin"></div>
                                        ) : (
                                            <MapPinIcon className="w-5 h-5" />
                                        )}
                                    </button>
                                </div>
                            </div>

                            {formData.latitude !== 0 && (
                                <p className="mt-2 text-[10px] font-bold text-green-600 flex items-center gap-1">
                                    <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
                                    Coordinates locked: {formData.latitude.toFixed(4)}, {formData.longitude.toFixed(4)}
                                </p>
                            )}
                        </div>


                        {error && (
                            <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg text-sm">
                                {error}
                            </div>
                        )}
                    </div>

                    {/* Footer */}
                    <div className="bg-gray-50 px-6 py-4 flex justify-end gap-3 border-t border-gray-200">
                        <button
                            type="button"
                            onClick={() => navigate('/admin/dashboard')}
                            className="px-6 py-2.5 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors font-medium"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            disabled={loading}
                            className={`px-6 py-2.5 rounded-lg font-medium text-white transition-all ${loading
                                ? 'bg-gray-400 cursor-not-allowed'
                                : 'bg-blue-600 hover:bg-blue-700 hover:shadow-lg'
                                }`}
                        >
                            {loading ? 'Creating...' : 'Create Product'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
};

export default CreateProduct;
