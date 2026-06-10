import { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeftIcon, TrashIcon, CloudArrowUpIcon, MapPinIcon } from '@heroicons/react/24/outline';
import client from '../../api/client';
import { getImageUrl } from '../../utils/image';
import locationService, { Province, Regency, District, Village } from '../../services/locationService';

const EditProduct = () => {
    const navigate = useNavigate();
    const { id } = useParams();
    const [categories, setCategories] = useState<any[]>([]);
    const [assets, setAssets] = useState<any[]>([]);
    const [loading, setLoading] = useState(false);
    const [uploading, setUploading] = useState(false);
    const [error, setError] = useState('');
    const [formData, setFormData] = useState({
        category_id: '',
        title: '',
        description: '',
        price: '',
        member_commission_amount: '',
        reseller_commission_amount: '',
        stock: '1', // Tambah field stock
        status: 'ACTIVE',
        location_name: '',
        latitude: 0 as number,
        longitude: 0 as number,
        province: '',
        regency: '',
        district: '',
        village: '',
    });
    const [specifications, setSpecifications] = useState<{ key: string; value: string }[]>([]);

    const addSpecification = () => {
        setSpecifications([...specifications, { key: '', value: '' }]);
    };

    const handleSpecificationChange = (index: number, field: 'key' | 'value', value: string) => {
        const updated = [...specifications];
        updated[index][field] = value;
        setSpecifications(updated);
    };

    const removeSpecification = (index: number) => {
        setSpecifications(specifications.filter((_, i) => i !== index));
    };

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
    const [detectingLocation, setDetectingLocation] = useState(false);

    useEffect(() => {
        const token = localStorage.getItem('token');
        if (!token) {
            navigate('/auth/login/admin');
            return;
        }
        loadCategories();
        loadProvinces();
        if (id) {
            loadProduct(id);
        }
    }, [navigate, id]);

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
        setLoadingLocations(true);
        try {
            const data = await locationService.getProvinces();
            setProvinces(data);
        } catch (err) {
            console.error('Failed to load provinces', err);
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

    const loadProduct = async (productId: string) => {
        try {
            const token = localStorage.getItem('token');
            const res = await client.get(`/admin/products/${productId}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            if (res.data && res.data.message_data) {
                const { product: p, assets: productAssets } = res.data.message_data;

                // Fallback if structure hasn't updated yet (for safety)
                const productData = p || res.data.message_data;
                const assetsData = productAssets || [];

                setFormData({
                    category_id: productData.category_id,
                    title: productData.title,
                    description: productData.description,
                    price: productData.price,
                    member_commission_amount: productData.member_commission_amount || 0,
                    reseller_commission_amount: productData.reseller_commission_amount || 0,
                    stock: productData.stock || 1, // Load stock
                    status: productData.status,
                    location_name: productData.location_name || '',
                    latitude: parseFloat(productData.latitude) || 0,
                    longitude: parseFloat(productData.longitude) || 0,
                    province: productData.province || '',
                    regency: productData.regency || '',
                    district: productData.district || '',
                    village: productData.village || '',
                });
                setAssets(assetsData);
                setSpecifications(productData.specifications || []);
            }
        } catch (err) {
            console.error('Failed to load product', err);
            setError('Failed to load product details');
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            const token = localStorage.getItem('token');
            // Filter out empty key specifications
            const filteredSpecs = specifications.filter(s => s.key.trim() !== '');

            await client.put(`/admin/products/${id}`, {
                ...formData,
                price: parseInt(String(formData.price)),
                member_commission_amount: parseInt(String(formData.member_commission_amount || 0)),
                reseller_commission_amount: parseInt(String(formData.reseller_commission_amount || 0)),
                stock: parseInt(String(formData.stock || 1)), // Include stock
                specifications: filteredSpecs
            }, {
                headers: { Authorization: `Bearer ${token}` }
            });

            alert('Product updated successfully!');
            navigate('/admin/dashboard');
        } catch (err: any) {
            console.error('Failed to update product', err);
            setError(err.response?.data?.message_data || 'Failed to update product');
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async () => {
        if (!window.confirm('Are you sure you want to delete this product? This action cannot be undone.')) {
            return;
        }

        try {
            const token = localStorage.getItem('token');
            await client.delete(`/admin/products/${id}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            alert('Product deleted successfully');
            navigate('/admin/dashboard');
        } catch (err: any) {
            console.error('Failed to delete product', err);
            setError('Failed to delete product');
        }
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

    const handleDeleteAsset = async (assetId: string) => {
        if (!window.confirm('Delete this image/video?')) return;
        try {
            const token = localStorage.getItem('token');
            await client.delete(`/admin/products/assets/${assetId}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setAssets(assets.filter(a => a.id !== assetId));
        } catch (err) {
            console.error('Failed to delete asset', err);
            alert('Failed to delete asset');
        }
    };

    const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
        if (!e.target.files || e.target.files.length === 0) return;

        const files = Array.from(e.target.files);
        const formData = new FormData();
        formData.append('product_id', id!);
        files.forEach(file => {
            formData.append('files', file);
        });

        setUploading(true);
        try {
            const token = localStorage.getItem('token');
            const res = await client.post('/admin/products/assets', formData, {
                headers: {
                    Authorization: `Bearer ${token}`,
                    'Content-Type': 'multipart/form-data'
                }
            });

            if (res.data && res.data.message_data && res.data.message_data.assets) {
                setAssets([...assets, ...res.data.message_data.assets]);
            } else {
                // Refresh product to be safe
                if (id) loadProduct(id);
            }
        } catch (err: any) {
            console.error('Upload failed', err);
            alert(err.response?.data?.error || 'Upload failed');
        } finally {
            setUploading(false);
            e.target.value = ''; // Reset input
        }
    };

    return (
        <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
            <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                {/* Header */}
                <div className="mb-8 flex justify-between items-start">
                    <div>
                        <button
                            onClick={() => navigate('/admin/dashboard')}
                            className="flex items-center gap-2 text-gray-600 hover:text-gray-900 mb-4 transition-colors"
                        >
                            <ArrowLeftIcon className="w-5 h-5" />
                            Back to Dashboard
                        </button>
                        <h1 className="text-3xl font-bold text-gray-900">Edit Product</h1>
                        <p className="text-gray-500 mt-1">Update product details and status</p>
                    </div>
                    <button
                        onClick={handleDelete}
                        className="flex items-center gap-2 px-4 py-2 bg-red-100 text-red-700 rounded-lg hover:bg-red-200 transition-colors font-medium"
                    >
                        <TrashIcon className="w-5 h-5" />
                        Delete Product
                    </button>
                </div>

                {/* Form */}
                <form onSubmit={handleSubmit} className="bg-white rounded-2xl shadow-lg border border-gray-100 overflow-hidden">
                    <div className="p-6 space-y-6">

                        {/* Status */}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                Status
                            </label>
                            <div className="flex gap-4">
                                {['ACTIVE', 'SOLD', 'INACTIVE', 'DRAFT'].map((status) => (
                                    <label key={status} className={`
                                        flex-1 cursor-pointer py-3 px-4 rounded-lg border-2 text-center text-sm font-medium transition-all
                                        ${formData.status === status
                                            ? 'border-blue-500 bg-blue-50 text-blue-700'
                                            : 'border-gray-200 hover:border-gray-300 text-gray-600'}
                                    `}>
                                        <input
                                            type="radio"
                                            name="status"
                                            value={status}
                                            checked={formData.status === status}
                                            onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                                            className="hidden"
                                        />
                                        {status}
                                    </label>
                                ))}
                            </div>
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
                                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                            />
                        </div>

                        {/* Specifications */}
                        <div className="pt-4 border-t border-gray-100">
                            <div className="flex justify-between items-center mb-2">
                                <label className="block text-sm font-bold text-gray-900">
                                    Spesifikasi / Detail Produk (Key-Value)
                                </label>
                                <button
                                    type="button"
                                    onClick={addSpecification}
                                    className="flex items-center gap-1 text-xs font-semibold text-blue-600 hover:text-blue-800 transition-colors"
                                >
                                    <span className="text-sm font-bold">+</span> Tambah Detail
                                </button>
                            </div>
                            {specifications.length === 0 ? (
                                <p className="text-xs text-gray-400 italic">Belum ada detail khusus. Klik &quot;+ Tambah Detail&quot; untuk menambahkan manual point (misal: Tahun: 2020, CC: 125).</p>
                            ) : (
                                <div className="space-y-3">
                                    {specifications.map((spec, index) => (
                                        <div key={index} className="flex gap-3 items-center">
                                            <input
                                                type="text"
                                                value={spec.key}
                                                onChange={(e) => handleSpecificationChange(index, 'key', e.target.value)}
                                                placeholder="Contoh: Tahun Keluaran, Luas, CC"
                                                className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all text-sm"
                                            />
                                            <span className="text-gray-400 text-sm font-bold">»</span>
                                            <input
                                                type="text"
                                                value={spec.value}
                                                onChange={(e) => handleSpecificationChange(index, 'value', e.target.value)}
                                                placeholder="Contoh: 2019, 100m2, 125cc"
                                                className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all text-sm"
                                            />
                                            <button
                                                type="button"
                                                onClick={() => removeSpecification(index)}
                                                className="text-red-500 hover:text-red-700 transition-colors"
                                                title="Hapus detail"
                                            >
                                                <TrashIcon className="w-5 h-5" />
                                            </button>
                                        </div>
                                    ))}
                                </div>
                            )}
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
                                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all resize-none"
                            />
                        </div>

                        {/* Assets Management */}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">Product Media (Images & Videos)</label>
                            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
                                {assets.map((asset) => (
                                    <div key={asset.id} className="relative group aspect-square bg-gray-100 rounded-lg overflow-hidden border border-gray-200">
                                        {asset.asset_type === 'IMAGE' || asset.asset_type === 'image' ? (
                                            <img src={getImageUrl(asset.object_key)} alt="Product Asset" className="w-full h-full object-cover" />
                                        ) : (
                                            <video src={getImageUrl(asset.object_key)} className="w-full h-full object-cover" controls />
                                        )}
                                        <button
                                            type="button"
                                            onClick={() => handleDeleteAsset(asset.id)}
                                            className="absolute top-2 right-2 p-1.5 bg-red-600/80 hover:bg-red-600 text-white rounded-full opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-all shadow-sm backdrop-blur-sm"
                                            title="Delete Asset"
                                        >
                                            <TrashIcon className="w-4 h-4" />
                                        </button>
                                    </div>
                                ))}

                                <label className={`border-2 border-dashed border-gray-300 rounded-lg flex flex-col items-center justify-center cursor-pointer hover:border-blue-500 hover:bg-blue-50 transition-colors aspect-square ${uploading ? 'opacity-50 cursor-not-allowed' : ''}`}>
                                    <CloudArrowUpIcon className="w-8 h-8 text-gray-400 mb-2" />
                                    <span className="text-gray-500 text-xs font-medium">{uploading ? 'Uploading...' : 'Add Media'}</span>
                                    <input
                                        type="file"
                                        multiple
                                        onChange={handleUpload}
                                        className="hidden"
                                        accept="image/*,video/*"
                                        disabled={uploading}
                                    />
                                </label>
                            </div>
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
                                    className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                                />
                            </div>
                        </div>

                        {/* Commissions */}
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label htmlFor="reseller_commission" className="block text-sm font-medium text-gray-700 mb-2">
                                    Reseller Commission (IDR) *
                                </label>
                                <div className="relative">
                                    <span className="absolute left-4 top-3 text-gray-500">Rp</span>
                                    <input
                                        id="reseller_commission"
                                        type="number"
                                        required
                                        min="0"
                                        value={formData.reseller_commission_amount}
                                        onChange={(e) => setFormData({ ...formData, reseller_commission_amount: e.target.value })}
                                        placeholder="0"
                                        className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                                    />
                                </div>
                                <p className="mt-1 text-xs text-gray-500">Untuk Reseller.</p>
                            </div>
                            <div>
                                <label htmlFor="member_commission" className="block text-sm font-medium text-gray-700 mb-2">
                                    Member Commission (IDR) *
                                </label>
                                <div className="relative">
                                    <span className="absolute left-4 top-3 text-gray-500">Rp</span>
                                    <input
                                        id="member_commission"
                                        type="number"
                                        required
                                        min="0"
                                        value={formData.member_commission_amount}
                                        onChange={(e) => setFormData({ ...formData, member_commission_amount: e.target.value })}
                                        placeholder="0"
                                        className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                                    />
                                </div>
                                <p className="mt-1 text-xs text-gray-500">Untuk Member (Leader).</p>
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
                                {Number(formData.stock) === 0 ? (
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
                            {loading ? 'Saving...' : 'Save Changes'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
};

export default EditProduct;
