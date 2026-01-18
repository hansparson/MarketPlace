/// <reference types="vite/client" />

interface ImportMetaEnv {
    readonly VITE_SELLER_NAME: string
    readonly VITE_WHATSAPP_NUMBER: string
    // more env variables...
}

interface ImportMeta {
    readonly env: ImportMetaEnv
}
