import { HeartIcon } from '@heroicons/react/24/solid';
import { Link } from 'react-router-dom';
import { getImageUrl } from '../utils/image';
import { formatRelativeTime } from '../utils/date';
import { useState } from 'react';

interface Product {
    id: string;
    title: string;
    price: number;
    description: string;
    status: 'ACTIVE' | 'SOLD' | 'DRAFT' | 'INACTIVE';
    created_at: string;
    thumbnail_url?: string;
    location?: string;
    province?: string;
    regency?: string;
}

interface ProductCardProps {
    product: Product;
    viewMode?: 'grid' | 'list';
}

const ProductCard = ({ product, viewMode = 'grid' }: ProductCardProps) => {
    const isSold = product.status === 'SOLD';
    const isList = viewMode === 'list';
    const [imageError, setImageError] = useState(false);

    // Format price
    const formattedPrice = new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        maximumFractionDigits: 0,
        minimumFractionDigits: 0
    }).format(product.price);



    if (isList) {
        return (
            <Link to={`/products/${product.id}`} className={`block transition-opacity duration-300 ${isSold ? 'opacity-75 grayscale-[0.5]' : ''}`}>
                <div className={`bg-white rounded-[24px] overflow-hidden hover:shadow-lg transition-all duration-300 group border flex h-[180px] sm:h-[200px] ${isSold ? 'border-gray-200' : 'border-gray-100'}`}>
                    {/* Image */}
                    <div className="product-image-container relative w-[40%] sm:w-1/3 md:w-1/4 h-full bg-gray-100 overflow-hidden shrink-0">
                        {!imageError ? (
                            <img
                                src={getImageUrl(product.thumbnail_url)}
                                alt={product.title}
                                loading="lazy"
                                className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700"
                                onError={() => setImageError(true)}
                            />
                        ) : (
                            <div className="w-full h-full flex items-center justify-center text-gray-300 bg-gray-100">
                                <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                </svg>
                            </div>
                        )}
                        {isSold && (
                            <div className="absolute inset-0 bg-black/10 flex items-center justify-center">
                                <span className="bg-red-600 text-[8px] font-black text-white px-2 py-0.5 rounded-full rotate-[-15deg]">SOLD</span>
                            </div>
                        )}
                    </div>

                    {/* Content */}
                    <div className="flex-1 p-4 sm:p-6 flex flex-col justify-between min-w-0">
                        <div>
                            <div className="mb-1">
                                <span className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">
                                    {product.regency || product.location || 'JAKARTA'} • {formatRelativeTime(product.created_at)}
                                </span>
                            </div>
                            <h3 className={`text-base sm:text-xl font-bold mb-1 truncate ${isSold ? 'text-gray-500 italic' : 'text-gray-900 group-hover:text-rose-600'}`}>{product.title}</h3>
                            <p className="text-xs text-gray-500 line-clamp-2 hidden sm:block">{product.description}</p>
                        </div>

                        <div className="flex items-end justify-between mt-2">
                            <div>
                                <span className="text-[10px] text-gray-400 font-medium block">{isSold ? 'Last Price' : 'Price'}</span>
                                <span className={`text-lg sm:text-2xl font-black ${isSold ? 'text-gray-400 line-through' : 'text-gray-900'}`}>{formattedPrice}</span>
                            </div>
                            <button className="hidden sm:flex px-4 py-2 bg-gray-900 text-white text-xs font-bold rounded-xl hover:bg-rose-600 transition-colors">
                                View Detail
                            </button>
                        </div>
                    </div>
                </div>
            </Link>
        );
    }

    return (
        <Link to={`/products/${product.id}`} className={`block h-full transition-opacity duration-300 ${isSold ? 'opacity-75 grayscale-[0.5]' : ''}`}>
            <div className={`bg-white rounded-[24px] overflow-hidden hover:shadow-xl transition-all duration-300 group border flex flex-col h-full ${isSold ? 'border-gray-200' : 'border-gray-100 hover:border-rose-100'}`}>
                {/* Image Container */}
                <div className="product-image-container product-thumbnail relative aspect-[4/3] bg-gray-100 overflow-hidden m-2 rounded-[20px]">
                    {!imageError ? (
                        <img
                            src={getImageUrl(product.thumbnail_url)}
                            alt={product.title}
                            loading="lazy"
                            className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700"
                            onError={() => setImageError(true)}
                        />
                    ) : (
                        <div className="w-full h-full flex flex-col gap-2 items-center justify-center text-gray-300 bg-gray-50">
                            <svg className="w-16 h-16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                            </svg>
                            <p className="text-xs font-medium">No image</p>
                        </div>
                    )}

                    {/* Heart Button */}
                    {!isSold && (
                        <button
                            className="absolute bottom-3 right-3 w-10 h-10 bg-white/90 backdrop-blur-sm rounded-full flex items-center justify-center shadow-md text-gray-400 hover:text-rose-500 hover:bg-white transition-all transform hover:scale-105"
                            onClick={(e) => { e.preventDefault(); }}
                        >
                            <HeartIcon className="w-5 h-5" />
                        </button>
                    )}

                    {/* Badge */}
                    <div className="absolute top-3 left-3 flex gap-2">
                        {isSold ? (
                            <div className="bg-red-600 px-3 py-1 rounded-full shadow-lg border border-red-500">
                                <span className="text-[10px] font-black text-white uppercase tracking-wider">SOLD OUT</span>
                            </div>
                        ) : (
                            <div className="bg-gray-900/60 backdrop-blur-md px-3 py-1 rounded-full">
                                <span className="text-[10px] font-bold text-white uppercase tracking-wider">FEATURED</span>
                            </div>
                        )}
                    </div>
                </div>

                {/* Content */}
                <div className="px-5 pb-5 pt-2 flex flex-col flex-1">
                    <div className="text-[10px] font-bold text-gray-400 uppercase mb-1 tracking-wider">
                        {product.regency || product.location || 'JAKARTA SELATAN'} • {formatRelativeTime(product.created_at)}
                    </div>

                    <h3 className={`text-lg font-bold mb-1 truncate transition-colors ${isSold ? 'text-gray-500 italic' : 'text-gray-900 group-hover:text-rose-600'}`}>
                        {product.title}
                    </h3>

                    <p className="text-xs text-gray-500 line-clamp-2 mb-4 h-8 leading-relaxed">
                        {product.description || 'No description available for this product.'}
                    </p>

                    <div className="mt-auto flex items-end justify-between border-t border-gray-50 pt-3 md:pb-1">
                        <div>
                            <span className="text-[10px] text-gray-400 font-medium block mb-0.5">{isSold ? 'Last Price' : 'Start From'}</span>
                            <span className={`text-base font-black ${isSold ? 'text-gray-400 line-through' : 'text-gray-900'}`}>{formattedPrice}</span>
                        </div>


                    </div>
                </div>
            </div>
        </Link>
    );
};

export default ProductCard;
