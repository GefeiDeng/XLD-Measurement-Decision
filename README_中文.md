# 小浪底测量决策论文：可复现工程

本工程只整理论文实际使用的内容，包含裁剪后的原始分辨率 DEM、左岸线、右岸线、深泓线、评价边界、七天原始 GPS，以及图3—图8的计算和绘图代码。图1的制图素材、图2的示意图绘制程序、未采用方案和历史重复缓存不在交付范围内。测线生成算法仍然保留，因为它是误差计算的必要环节。

## 如何运行

在 MATLAB 中打开本文件夹：

```matlab
check_environment   % 检查依赖
run_figures         % 用参考结果快速复画图3—图8
run_all             % 从原始数据开始重新计算，最后绘图
```

快速绘图读取 `reference/` 中明确标注的参考结果；完整计算读取 `data/raw/`，新结果写入 `results/`，最终图片写入 `figures/computed/`。两条入口不混用计算结果。交付时的验证范围见 `validation/VALIDATION.md`。

完整流程包含五步：原始 GPS 处理与转弯率定；33种测线布局的全域地形重构；RMSE—时间拟合与工程决策；绘图数据整理；转弯系数变化下的交点计算。可以执行 `setup_project` 后单独调用 `analysis/` 中的 `step01` 至 `step05`，按顺序运行。

33个布局均评价 13,110,629 个 DEM 像元，因此全流程计算量较大。程序对每个布局保存完成标记和数据、代码、参数指纹，允许复用一致的完整结果继续计算。不要将快速复画理解为已经重新运行了全部地形插值。

## 数据和环境

- MATLAB R2024b；Mapping、Image Processing、Statistics and Machine Learning、Optimization 四个工具箱。
- Python 3 和 `pypdf==6.10.0`，用于 PDF 页面尺寸及9 pt字体的统一。执行 `python -m pip install -r requirements.txt` 安装。
- Times New Roman 字体。默认通过 PATH 中的 `python` 调用，也可以在 MATLAB 中用 `setenv('IJSR_PYTHON','自己的python.exe路径')` 指定。
- 安装依赖后不需要联网，不依赖原来的作者目录或 Codex 环境。建议至少16 GB内存，并为中间地形和测线结果预留数 GB 空间。

DEM 保持0.5 m网格、高程原值及像元位置，按研究区包络范围裁剪，外留10 m插值缓冲。评价边界另行提供，不能用矩形裁剪范围代替。三条几何线是论文实际采用的配对映射线，835个站点一一对应；不是早期未采用的岸线草稿。七天 GPS 保留清洗前的记录，MAT文件保存完整时间精度，CSV用于直接查看和跨软件读取。

文件夹职责、每张图对应的数据和程序见英文 `README.md` 的表格；数据字段和单位见 `DATA_DICTIONARY.md`。`reference/layouts.csv` 给出全部33个布局、两种平台的数值结果；`figures/reference/data/` 给出直接用于图表的主要CSV数据。图4的小型栅格只是显示用采样，完整计算仍使用所有有效评价像元。

后续生成公开数据 DOI 时，可直接以这个目录为基础打包，并补充正式引用信息和发布许可；本工程没有虚构 DOI。
