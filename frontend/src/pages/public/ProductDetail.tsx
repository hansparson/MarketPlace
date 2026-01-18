import { useState, useEffect } from 'react';
import { useParams, useNavigate, useSearchParams } from 'react-router-dom';
import { Helmet } from 'react-helmet-async';
import client from '../api/client';
import Navbar from '../components/Navbar';
import {
    ChevronLeftIcon,
    ChevronRightIcon,
    ChatBubbleLeftRightIcon,
    ShareIcon,
    ArrowLeftIcon,
    PhotoIcon,
    MapPinIcon,
    ClockIcon,
} from '@heroicons/react/24/outline';
import { StarIcon as StarIconSolid } from '@heroicons/react/24/solid';
import { getImageUrl } from '../utils/image';
import { formatRelativeTime } from '../utils/date';

const ProductDetail = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const [searchParams] = useSearchParams();

    const [product, setProduct] = useState<any>(null);
    const [assets, setAssets] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [activeImageIndex, setActiveImageIndex] = useState(0);
    const [isReseller, setIsReseller] = useState(false);

    // Lead Capture
    const [showLeadModal, setShowLeadModal] = useState(false);
    const [showShareModal, setShowShareModal] = useState(false);
    const [leadForm, setLeadForm] = useState({ name: '', phone: '' });
    const [isSubmitting, setIsSubmitting] = useState(false);

    useEffect(() => {
        loadProduct();
        const role = localStorage.getItem('role');
        setIsReseller(role === 'RESELLER');

        // Check for referral and lead capture
        const ref = searchParams.get('ref');
        if (ref && id) {
            // Don't capture leads from Resellers or Admins
            if (role === 'RESELLER' || role === 'ADMIN' || role === 'SUPER_ADMIN') {
                return;
            }

            const captured = sessionStorage.getItem(`lead_captured_${id}`);
            if (!captured) {
                setShowLeadModal(true);
            }
        }
    }, [id, searchParams]);

    const loadProduct = async () => {
        try {
            const res = await client.get(`/products/${id}`);
            if (res.data && res.data.message_data) {
                setProduct(res.data.message_data.product);
                setAssets(res.data.message_data.assets || []);
            }
        } catch (err) {
            console.error("Failed to load product", err);
        } finally {
            setLoading(false);
        }
    };

    const handleWhatsapp = () => {
        if (!product) return;

        let phone = import.meta.env.VITE_WHATSAPP_NUMBER || product.seller_phone || '081272719765';
        phone = phone.replace(/\D/g, '');

        if (phone.startsWith('0')) {
            phone = '62' + phone.slice(1);
        } else if (!phone.startsWith('62') && phone.length > 5) {
            phone = '62' + phone;
        }

        // Buat link produk (gunakan window.location.origin untuk support semua environment)
        const productUrl = `${window.location.origin}/products/${id}`;

        const text = encodeURIComponent(
            `Halo Zeth Lintin, saya ingin tahu lebih lanjut tentang produk *${product.title}* di Gostar Mart.\n\n` +
            `Link Produk: ${productUrl}\n\n` +
            `Bisa dibantu informasinya?`
        );

        window.open(`https://api.whatsapp.com/send?phone=${phone}&text=${text}`, '_blank');
    };

    const handleShare = () => {
        setShowShareModal(true);
    };

    const formatPrice = (price: number) => {
        return new Intl.NumberFormat('id-ID', {
            style: 'currency',
            currency: 'IDR',
            minimumFractionDigits: 0
        }).format(price);
    };

    const handleLeadSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!leadForm.phone) return;
        setIsSubmitting(true);
        try {
            const ref = searchParams.get('ref');
            await client.post('/leads', {
                product_id: id,
                ref_code: ref,
                phone: leadForm.phone,
                name: leadForm.name
            });
            sessionStorage.setItem(`lead_captured_${id}`, 'true');
            setShowLeadModal(false);
        } catch (err) {
            console.error('Failed to submit lead', err);
            alert('Terjadi kesalahan, silakan coba lagi.');
        } finally {
            setIsSubmitting(false);
        }
    };

    if (loading) {
        return (
            <div className="min-h-screen bg-gray-50">
                <Navbar />
                <div className="flex justify-center items-center h-[calc(100vh-64px)]">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-rose-600"></div>
                </div>
            </div>
        );
    }

    if (!product) {
        return (
            <div className="min-h-screen bg-gray-50">
                <Navbar />
                <div className="max-w-7xl mx-auto px-4 py-8 text-center text-gray-500">
                    Product not found.
                </div>
            </div>
        );
    }

    const images = assets.filter(a => a.asset_type === 'IMAGE' || a.asset_type === 'image');
    const hasImages = images.length > 0;

    // Dapatkan URL gambar produk untuk Open Graph
    const productImageUrl = hasImages
        ? getImageUrl(images[0].object_key)
        : `${window.location.origin}/logo.jpg`;

    // URL produk saat ini
    const productUrl = `${window.location.origin}/products/${id}`;

    // Deskripsi singkat untuk meta tags (max 160 karakter)
    const metaDescription = product.description
        ? product.description.substring(0, 157) + '...'
        : `${product.title} - ${formatPrice(product.price)}`;

    return (
        <div className="min-h-screen bg-gray-50 pb-20 sm:pb-0">
            {/* Dynamic Meta Tags untuk Social Media Sharing */}
            <Helmet>
                <title>{product.title} - Gostar Mart</title>
                <meta name="description" content={metaDescription} />

                {/* Open Graph / Facebook / WhatsApp */}
                <meta property="og:type" content="product" />
                <meta property="og:site_name" content="Gostar Mart" />
                <meta property="og:title" content={product.title} />
                <meta property="og:description" content={metaDescription} />
                <meta property="og:image" content={productImageUrl} />
                <meta property="og:image:width" content="1200" />
                <meta property="og:image:height" content="630" />
                <meta property="og:url" content={productUrl} />
                <meta property="product:price:amount" content={product.price.toString()} />
                <meta property="product:price:currency" content="IDR" />

                {/* Twitter */}
                <meta name="twitter:card" content="summary_large_image" />
                <meta name="twitter:title" content={product.title} />
                <meta name="twitter:description" content={metaDescription} />
                <meta name="twitter:image" content={productImageUrl} />

                {/* WhatsApp khusus - gunakan og: tags */}
                <meta property="og:image:secure_url" content={productImageUrl} />
                <meta property="og:image:type" content="image/jpeg" />
            </Helmet>

            <Navbar />

            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8">
                {/* Back Button */}
                <button
                    onClick={() => navigate(-1)}
                    className="flex items-center gap-2 text-gray-500 hover:text-gray-900 mb-4 sm:mb-6 transition-colors text-xs sm:text-sm font-bold uppercase tracking-widest"
                >
                    <ArrowLeftIcon className="w-4 h-4" />
                    Back to Marketplace
                </button>

                <div className="bg-white rounded-[32px] shadow-sm border border-gray-100 overflow-hidden">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-0 md:gap-8">

                        {/* Image Section */}
                        <div className="p-4 sm:p-8 bg-gray-50/50 flex flex-col items-center justify-center relative">
                            {hasImages ? (
                                <div className="product-image-container product-detail-image relative w-full aspect-square max-w-lg mx-auto bg-white rounded-[24px] overflow-hidden shadow-sm border border-gray-100">
                                    <img
                                        src={getImageUrl(images[activeImageIndex].object_key)}
                                        alt={product.title}
                                        className="w-full h-full object-contain"
                                        loading="eager"
                                        onError={(e) => {
                                            const target = e.target as HTMLImageElement;
                                            target.style.display = 'none';
                                            const parent = target.parentElement;
                                            if (parent) {
                                                parent.innerHTML = '<div class="w-full h-full flex flex-col items-center justify-center text-gray-400 bg-gray-50"><svg class="w-24 h-24 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg><p class="text-sm font-medium">Gambar tidak tersedia</p></div>';
                                            }
                                        }}
                                    />

                                    {/* Slider Controls */}
                                    {images.length > 1 && (
                                        <>
                                            <button
                                                onClick={() => setActiveImageIndex(prev => prev === 0 ? images.length - 1 : prev - 1)}
                                                className="absolute left-4 top-1/2 -translate-y-1/2 p-2.5 rounded-full bg-white/90 backdrop-blur-md hover:bg-white shadow-lg shadow-black/5 transition-all active:scale-90"
                                            >
                                                <ChevronLeftIcon className="w-5 h-5 text-gray-800" />
                                            </button>
                                            <button
                                                onClick={() => setActiveImageIndex(prev => prev === images.length - 1 ? 0 : prev + 1)}
                                                className="absolute right-4 top-1/2 -translate-y-1/2 p-2.5 rounded-full bg-white/90 backdrop-blur-md hover:bg-white shadow-lg shadow-black/5 transition-all active:scale-90"
                                            >
                                                <ChevronRightIcon className="w-5 h-5 text-gray-800" />
                                            </button>

                                            {/* Dots indicator */}
                                            <div className="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-1.5 p-1.5 bg-black/10 backdrop-blur-md rounded-full">
                                                {images.map((_, idx) => (
                                                    <button
                                                        key={idx}
                                                        onClick={() => setActiveImageIndex(idx)}
                                                        className={`h-1.5 rounded-full transition-all duration-300 ${idx === activeImageIndex ? 'bg-white w-4' : 'bg-white/40 w-1.5'
                                                            }`}
                                                    />
                                                ))}
                                            </div>
                                        </>
                                    )}
                                </div>
                            ) : (
                                <div className="w-full aspect-square max-w-lg bg-gray-200 rounded-[24px] flex items-center justify-center text-gray-400">
                                    <PhotoIcon className="w-16 h-16" />
                                </div>
                            )}

                            {/* Thumbnails */}
                            {images.length > 1 && (
                                <div className="flex gap-3 mt-6 overflow-x-auto py-2 w-full justify-start sm:justify-center scrollbar-hide px-2">
                                    {images.map((img, idx) => (
                                        <button
                                            key={img.id}
                                            onClick={() => setActiveImageIndex(idx)}
                                            className={`product-image-container product-thumbnail relative w-16 h-16 sm:w-20 sm:h-20 flex-shrink-0 rounded-[16px] overflow-hidden border-2 transition-all duration-300 ${idx === activeImageIndex ? 'border-rose-500 scale-105 shadow-md shadow-rose-100' : 'border-transparent opacity-60'
                                                }`}
                                        >
                                            <img
                                                src={getImageUrl(img.object_key)}
                                                alt={`Thumbnail ${idx}`}
                                                className="w-full h-full object-cover"
                                                loading="lazy"
                                                onError={(e) => {
                                                    const target = e.target as HTMLImageElement;
                                                    target.style.display = 'none';
                                                    const parent = target.parentElement;
                                                    if (parent) {
                                                        parent.innerHTML = '<div class="w-full h-full flex items-center justify-center text-gray-300 bg-gray-50"><svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg></div>';
                                                    }
                                                }}
                                            />
                                        </button>
                                    ))}
                                </div>
                            )}
                        </div>

                        {/* Product Info Section */}
                        <div className="p-6 sm:p-8 flex flex-col">
                            <div className="mb-auto">
                                <div className="flex items-center gap-2 mb-3">
                                    <span className="px-2.5 py-1 bg-blue-50 text-blue-600 text-[10px] font-black uppercase tracking-wider rounded-lg border border-blue-100 italic">OFFICIAL</span>
                                    {product.status !== 'ACTIVE' && (
                                        <span className="px-2.5 py-1 bg-red-50 text-red-600 text-[10px] font-black uppercase tracking-wider rounded-lg border border-red-100 italic">{product.status}</span>
                                    )}
                                </div>
                                <h1 className="text-2xl sm:text-3xl md:text-4xl font-extrabold text-gray-900 mb-2 leading-tight tracking-tight">{product.title}</h1>

                                <div className="flex items-baseline gap-2 mb-4">
                                    <span className="text-2xl sm:text-4xl font-black text-rose-600">
                                        {formatPrice(product.price)}
                                    </span>
                                </div>

                                {/* Stock Indicator */}
                                <div className="mb-6">
                                    {product.stock > 0 ? (
                                        <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-green-50 border border-green-200 rounded-xl">
                                            <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
                                            <span className="text-xs font-black text-green-700 uppercase tracking-wider">
                                                {product.stock} unit tersedia
                                            </span>
                                        </div>
                                    ) : (
                                        <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-red-50 border border-red-200 rounded-xl">
                                            <div className="w-2 h-2 bg-red-500 rounded-full"></div>
                                            <span className="text-xs font-black text-red-700 uppercase tracking-wider">
                                                Stok Habis
                                            </span>
                                        </div>
                                    )}
                                </div>

                                {product.location_name && (
                                    <div className="flex flex-col sm:flex-row sm:items-center gap-3 sm:gap-6 text-gray-500 mb-8 p-4 bg-gray-50 rounded-2xl border border-gray-100">
                                        <div className="flex items-center gap-2 group cursor-pointer hover:text-rose-500 transition-colors">
                                            <div className="p-2 bg-rose-100/50 text-rose-600 rounded-xl group-hover:bg-rose-100 border border-rose-200">
                                                <MapPinIcon className="w-4 h-4" />
                                            </div>
                                            <span className="text-xs sm:text-sm font-black tracking-tight">{product.location_name}</span>
                                        </div>
                                        <div className="hidden sm:block w-px h-4 bg-gray-300"></div>
                                        <div className="flex items-center gap-2">
                                            <div className="p-2 bg-blue-100/50 text-blue-600 rounded-xl border border-blue-200">
                                                <ClockIcon className="w-4 h-4" />
                                            </div>
                                            <span className="text-xs sm:text-sm text-gray-500 font-black">Diposting {formatRelativeTime(product.created_at)}</span>
                                        </div>
                                    </div>
                                )}

                                {isReseller && product.commission_amount > 0 && (
                                    <div className="mb-8 p-5 bg-gradient-to-br from-green-50 to-emerald-50 border border-green-100 rounded-[24px] flex items-center justify-between shadow-sm shadow-green-100">
                                        <div>
                                            <p className="text-[10px] text-green-600 font-black uppercase tracking-wider mb-1 flex items-center gap-1">
                                                <StarIconSolid className="w-3 h-3" />
                                                Potensi Komisi Reseller
                                            </p>
                                            <p className="text-xl sm:text-2xl font-black text-green-700">{formatPrice(product.commission_amount)}</p>
                                        </div>
                                        <div className="w-12 h-12 bg-white rounded-2xl flex items-center justify-center text-green-600 shadow-sm border border-green-100">
                                            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                                        </div>
                                    </div>
                                )}

                                <div className="mb-10">
                                    <h3 className="text-gray-900 text-sm font-black uppercase tracking-[0.1em] mb-3 border-l-4 border-rose-500 pl-3">Deskripsi Produk</h3>
                                    <p className="text-sm sm:text-base text-gray-600 leading-relaxed font-medium whitespace-pre-line">
                                        {product.description}
                                    </p>
                                </div>

                                <div className="border-t border-gray-100 pt-8 mb-8">
                                    <h3 className="text-gray-900 text-sm font-black uppercase tracking-[0.1em] mb-4">Informasi Penjual</h3>
                                    <div className="flex items-center gap-4 p-5 bg-gray-50/50 rounded-[24px] border border-gray-100 hover:bg-white hover:shadow-md transition-all cursor-pointer">
                                        <div className="relative">
                                            <div className="w-14 h-14 sm:w-16 sm:h-16 rounded-full bg-blue-600 flex items-center justify-center text-white font-black text-xl shadow-inner border-4 border-white ring-1 ring-blue-100 overflow-hidden">
                                                <img
                                                    src="https://ui-avatars.com/api/?name=Zeth+Lintin&background=2563eb&color=fff&size=128"
                                                    alt="Zeth Lintin"
                                                    className="w-full h-full object-cover"
                                                />
                                            </div>
                                            <div className="absolute right-0 bottom-0 w-4 h-4 bg-green-500 border-2 border-white rounded-full shadow-sm animate-pulse"></div>
                                        </div>
                                        <div>
                                            <div className="flex items-center gap-1.5">
                                                <p className="font-extrabold text-gray-900 text-lg sm:text-xl leading-tight">{import.meta.env.VITE_SELLER_NAME || 'Zeth Lintin'}</p>
                                                <svg className="w-5 h-5 text-blue-500" fill="currentColor" viewBox="0 0 20 20"><path d="M6.267 3.455a3.066 3.066 0 001.745-.723 3.066 3.066 0 013.976 0 3.066 3.066 0 001.745.723 3.066 3.066 0 012.812 2.812c.051.633.326 1.254.723 1.745a3.066 3.066 0 010 3.976 3.066 3.066 0 00-.723 1.745 3.066 3.066 0 01-2.812 2.812 3.066 3.066 0 00-1.745.723 3.066 3.066 0 01-3.976 0 3.066 3.066 0 00-1.745-.723 3.066 3.066 0 01-2.812-2.812 3.066 3.066 0 00-.723-1.745 3.066 3.066 0 010-3.976 3.066 3.066 0 00.723-1.745 3.066 3.066 0 012.812-2.812zm7.44 5.252a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"></path></svg>
                                            </div>
                                            <p className="text-xs font-bold text-blue-600 uppercase tracking-widest mt-0.5">Verified Official Seller</p>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {/* Action Buttons - Desktop */}
                            <div className="hidden sm:block mt-8 space-y-4">
                                <button
                                    onClick={handleWhatsapp}
                                    className="w-full flex items-center justify-center gap-3 px-6 py-5 bg-green-500 text-white rounded-[20px] hover:bg-green-600 hover:shadow-xl hover:shadow-green-100 transition-all font-black text-lg active:scale-[0.98]"
                                >
                                    <ChatBubbleLeftRightIcon className="w-7 h-7" />
                                    Tanya Penjual (WhatsApp)
                                </button>

                                {isReseller && (
                                    <button
                                        onClick={handleShare}
                                        className="w-full flex items-center justify-center gap-3 px-6 py-5 bg-white text-blue-600 border-2 border-blue-100 rounded-[20px] hover:bg-blue-50 hover:border-blue-200 transition-all font-black text-lg"
                                    >
                                        <ShareIcon className="w-7 h-7" />
                                        Bagikan Link Referral
                                    </button>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Mobile Sticky Action Bar */}
            <div className="sm:hidden fixed bottom-0 left-0 right-0 bg-white/80 backdrop-blur-xl border-t border-gray-100 p-4 z-40 flex gap-3 pb-[max(1rem,env(safe-area-inset-bottom))] shadow-[0_-8px_30px_rgb(0,0,0,0.04)]">
                <button
                    onClick={handleWhatsapp}
                    className="flex-[2] flex items-center justify-center gap-2 px-6 py-4 bg-green-500 text-white rounded-2xl font-black text-sm active:scale-95 transition-all shadow-lg shadow-green-100"
                >
                    <ChatBubbleLeftRightIcon className="w-5 h-5" />
                    CHAT WA
                </button>
                {isReseller && (
                    <button
                        onClick={handleShare}
                        className="flex-1 flex items-center justify-center gap-2 px-6 py-4 bg-blue-50 text-blue-600 rounded-2xl font-black text-sm border border-blue-100 active:scale-95 transition-all"
                    >
                        <ShareIcon className="w-5 h-5" />
                        SHARE
                    </button>
                )}
            </div>

            {/* Lead Capture Modal */}
            {showLeadModal && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
                    <div className="bg-white rounded-2xl w-full max-w-md p-8 shadow-2xl animate-in fade-in zoom-in duration-300">
                        <div className="text-center mb-6">
                            <h2 className="text-2xl font-bold text-gray-900">Selamat Datang!</h2>
                            <p className="text-gray-600 mt-2">Untuk melanjutkan melihat detail produk promo ini, mohon isi data diri Anda.</p>
                        </div>
                        <form onSubmit={handleLeadSubmit} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">Nama Lengkap</label>
                                <input
                                    type="text"
                                    required
                                    className="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-rose-500 outline-none"
                                    placeholder="Contoh: Budi Santoso"
                                    value={leadForm.name}
                                    onChange={(e) => setLeadForm({ ...leadForm, name: e.target.value })}
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">Nomor WhatsApp</label>
                                <input
                                    type="tel"
                                    required
                                    className="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-rose-500 outline-none"
                                    placeholder="Contoh: 08123456789"
                                    value={leadForm.phone}
                                    onChange={(e) => setLeadForm({ ...leadForm, phone: e.target.value })}
                                />
                            </div>
                            <button
                                type="submit"
                                disabled={isSubmitting}
                                className="w-full py-4 bg-rose-600 text-white font-black rounded-xl hover:bg-rose-700 transition-all flex justify-center items-center shadow-lg shadow-rose-100"
                            >
                                {isSubmitting ? (
                                    <div className="w-5 h-5 border-2 border-white/50 border-t-white rounded-full animate-spin"></div>
                                ) : (
                                    'Lanjut Lihat Produk'
                                )}
                            </button>
                        </form>
                    </div>
                </div>
            )}

            {/* Share Modal */}
            {showShareModal && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
                    <div className="bg-white rounded-[32px] shadow-2xl max-w-sm w-full overflow-hidden animate-in fade-in zoom-in duration-200">
                        <div className="p-6 border-b border-gray-100 flex justify-between items-center">
                            <h3 className="text-xl font-bold text-gray-900">Bagikan Produk</h3>
                            <button onClick={() => setShowShareModal(false)} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                                <svg className="w-6 h-6 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
                            </button>
                        </div>
                        <div className="p-6">
                            <div className="grid grid-cols-2 gap-4">
                                <button
                                    onClick={() => {
                                        const refCode = localStorage.getItem('referral_code');
                                        const url = `${window.location.origin}/products/${id}${refCode ? `?ref=${refCode}` : ''}`;
                                        const text = encodeURIComponent(`Cek produk menarik ini: ${product.title}\n${url}`);
                                        window.open(`https://wa.me/?text=${text}`, '_blank');
                                    }}
                                    className="flex flex-col items-center gap-2 p-4 rounded-2xl bg-green-50 hover:bg-green-100 transition-colors border border-green-100 group"
                                >
                                    <div className="w-12 h-12 bg-green-500 rounded-full flex items-center justify-center text-white shadow-lg group-hover:scale-110 transition-transform">
                                        <ChatBubbleLeftRightIcon className="w-6 h-6" />
                                    </div>
                                    <span className="text-sm font-bold text-green-700">WhatsApp</span>
                                </button>

                                <button
                                    onClick={() => {
                                        const refCode = localStorage.getItem('referral_code');
                                        const url = encodeURIComponent(`${window.location.origin}/products/${id}${refCode ? `?ref=${refCode}` : ''}`);
                                        window.open(`https://www.facebook.com/sharer/sharer.php?u=${url}`, '_blank');
                                    }}
                                    className="flex flex-col items-center gap-2 p-4 rounded-2xl bg-blue-50 hover:bg-blue-100 transition-colors border border-blue-100 group"
                                >
                                    <div className="w-12 h-12 bg-[#1877F2] rounded-full flex items-center justify-center text-white shadow-lg group-hover:scale-110 transition-transform">
                                        <svg className="w-6 h-6 fill-current" viewBox="0 0 24 24"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" /></svg>
                                    </div>
                                    <span className="text-sm font-bold text-blue-700">Facebook</span>
                                </button>

                                <button
                                    onClick={() => {
                                        const refCode = localStorage.getItem('referral_code');
                                        const url = `${window.location.origin}/products/${id}${refCode ? `?ref=${refCode}` : ''}`;
                                        const text = encodeURIComponent(`Cek produk ${product.title} di Gostar Mart!`);
                                        window.open(`https://twitter.com/intent/tweet?url=${encodeURIComponent(url)}&text=${text}`, '_blank');
                                    }}
                                    className="flex flex-col items-center gap-2 p-4 rounded-2xl bg-gray-50 hover:bg-gray-100 transition-colors border border-gray-100 group"
                                >
                                    <div className="w-12 h-12 bg-black rounded-full flex items-center justify-center text-white shadow-lg group-hover:scale-110 transition-transform">
                                        <svg className="w-5 h-5 fill-current" viewBox="0 0 24 24"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" /></svg>
                                    </div>
                                    <span className="text-sm font-bold text-gray-900">Twitter / X</span>
                                </button>

                                <button
                                    onClick={() => {
                                        const refCode = localStorage.getItem('referral_code');
                                        const url = `${window.location.origin}/products/${id}${refCode ? `?ref=${refCode}` : ''}`;
                                        navigator.clipboard.writeText(url);
                                        alert('Link berhasil disalin!');
                                        setShowShareModal(false);
                                    }}
                                    className="flex flex-col items-center gap-2 p-4 rounded-2xl bg-rose-50 hover:bg-rose-100 transition-colors border border-rose-100 group"
                                >
                                    <div className="w-12 h-12 bg-rose-600 rounded-full flex items-center justify-center text-white shadow-lg group-hover:scale-110 transition-transform">
                                        <ShareIcon className="w-6 h-6" />
                                    </div>
                                    <span className="text-sm font-bold text-rose-700">Salin Link</span>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default ProductDetail;
