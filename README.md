# MeshAmbientOculussion
マテリアル単位でメッシュにAmbientOculussionを適用できるシェーダーです。
![image](https://github.com/sigmal00/MeshAmbientOculussion/assets/101445526/c87b4ec9-9927-4860-96ea-54c6f62ba74f)

## 導入方法
1. AOを適用したいメッシュをMeshRendererコンポーネントのMateriarlsのSizeを1増やします。
2. 増えたスロットに本シェーダーを適用したマテリアルを設定します。

![image](https://github.com/sigmal00/MeshAmbientOculussion/assets/101445526/aa74531a-59f6-489b-8f89-50a7e3f7a0c6)

### VRChatのアバターに本シェーダーを適用しようとしている人向け
本シェーダーはシェーダー内でDepthTextureを使用しているため、動作には影付きのリアルタイムなDirectionalLightが必要になります。
アバターの直下に以下のようなDirectionalLightを入れてください。

![image](https://github.com/sigmal00/MeshAmbientOculussion/assets/101445526/1d699375-e4be-43ff-b1bd-9aa4da2dca0b)

※CullingMaskはPlayerLocalよりUIとかにした方がより負荷が減るような気もしますが、ワールドにどの程度影響が出るか分からないのでオススメはしないでおきます……

## マテリアルパラメータ
基本的にRadiusとColorをいじれば大丈夫です。

### Color
AOの色です。元のメッシュの色に乗算されます。

### Intensity
AOの強度です。

### Exponent
AOの際のフェード具合が調整できます。

### Radius
AOをサンプリングする際の半径です。

### MaskTexture
AOが適用される範囲のマスクです。
