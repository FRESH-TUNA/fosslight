<%@ page contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ include file="/WEB-INF/constants.jsp"%>

<script>
    var ossData = [];
    var grid = "#list";
    var licenseNames = [];

    function showErrorMsg() {

        alertify.error('<spring:message code="msg.common.valid"/>', 0);

        $('.ajax-file-upload-statusbar').fadeOut('slow');
        $('.ajax-file-upload-statusbar').remove();
    }

    $(document).ready(function()
    {

        $("#btn").click(() => {
            $.ajax({
                type: "POST",
                contentType: 'application/json',
                url: "/oss/bulkRegAjax",
                data: JSON.stringify(OssBulkGridUtils.bulkSaveRequestData()),
                dataType: "json",
                success: (data) => {
                    if (data['res'] == true && data['value'] != []) {
                        fn.checkLoaded(data['value']);
                        alertify.alert('<spring:message code="msg.common.success" />', function(){});
                    } else if (data['res'] == false) {
                            showErrorMsg();
                    }
                },
                error: (e) => {
                    console.log(e);
                }
            })
        })


        $("#list").jqGrid({
            datatype: "local",
            data : ossData,
            colNames:['id', 'OSS Name','Nickname','Version','Declared License','Detected License','Copyright',
                'Homepage','Download URL',  'Summary Description', 'Attribution','Comment', 'Status'],
            colModel: [
                { name: 'gridId', 	index: 'gridId', width: 75, key:true, hidden: true},
                {name: 'ossName', index: 'ossName', width: 200, align: 'left'},
                {name: 'ossNicknames', index: 'ossNickNames', width: 200, align: 'left', editable:true},
                {name: 'ossVersion', index: 'ossVersion', width: 75, align: 'left'},
                { name: 'declaredLicenses', index: 'declaredLicenses', width: 300, align: 'left', editable:true, template: searchStringOptions,
                    editoptions: {
                        /**
                         * editRow로 인해 활성화 되었을때 실행된다.
                         */
                        dataInit: function (e) {

                            /**
                             * declaredlicenses 버튼 dom 삽입하기
                             */
                            var licenseNameId = $(e).attr("id").split('_')[0];
                            var licenseNameTd = $(e).parent();

                            console.log(licenseNameId + " init!");

                            var displayLicenseNameCell = '<div style="width:100%; display:table; table-layout:fixed;">';
                            displayLicenseNameCell += '<div id="' + licenseNameId + '_declaredLicensesDiv" style="width:60px; display:table-cell; vertical-align:middle;"></div>';
                            displayLicenseNameCell += '<div id="' + licenseNameId + '_declaredLicensesBtn" style="display:table-cell; vertical-align:middle;"></div>';
                            displayLicenseNameCell += '</div>';

                            $(licenseNameTd).empty();
                            $(licenseNameTd).html(displayLicenseNameCell);
                            $('#' + licenseNameId + '_declaredLicensesDiv').append(e);

                            /**
                             * autocomplete
                             */
                            // licenseName auto complete
                            $(e).autocomplete({
                                source: licenseNames
                                , minLength: 0
                                , open: function() { $(this).attr('state', 'open'); }
                                , close: function () { $(this).attr('state', 'closed'); }
                            }).focus(function() {
                                if ($(this).attr('state') != 'open') {
                                    $(this).autocomplete("search");
                                }
                            });

                            /**
                             * event handler 등록
                             */
                            $(e).on("keypress", function(evt) {
                                if (evt.keyCode == 13)
                                    OssBulkGridEventHandlers.autoAddDeclaredLicenseDoms(e);
                            }).on("autocompletechange", function(evt) {
                                OssBulkGridEventHandlers.autoAddDeclaredLicenseDoms(e);
                            });
                        }
                    }
                },
                { name: 'detectedLicenses', index: 'detectedLicenses', width: 300, align: 'left'},
                { name: 'copyright', index: 'copyright', width: 200, align: 'left'},
                { name: 'homepage', index:'homepage', width: 250, align: 'left'},
                { name: 'downloadLocation', index:'downloadLocation', width: 150, align: 'left'},
                { name: 'summaryDescription', index:'summaryDescription', width: 150, align: 'left'},
                { name: 'attribution', index:'attribution', width: 150, align: 'left'},
                { name: 'comment', index:'comment', width: 150, align: 'left'},
                { name: 'status', index:'status', width: 150, align: 'left'}
            ],
            viewrecords: true,
            rowNum: ${ct:getConstDef("DISP_PAGENATION_DEFAULT")},
            rowList: [${ct:getConstDef("DISP_PAGENATION_LIST_STR")}],
            autowidth: true,
            gridview: true,
            height: 'auto',
            pager: '#pager',
            // cellEdit: true,
            // cellsubmit : 'clientArray',
            ondblClickRow: function(rowid,iRow,iCol,e) {
                //saveLastRow


                // editable 하게 설정
                //fn_grid_com.setCellEdit(OssBulkGridUtils.getGrid(), rowid, srcValidMsgData, srcDiffMsgData, null, com_fn.getLicenseName);

                OssBulkGridUtils.editRow(rowid);
                //OssBulkGridUtils.getGrid().jqGrid('editRow',rowid, {keys: true, url: 'clientArray'});
                // 서브 그리드 제외
                // ondblClickRowBln = false;
                //
                $('#'+rowid+'_declaredLicenses').addClass('autoCom');
                $('#'+rowid+'_declaredLicenses').css({'width' : '100%'});
                //
                var result = $('#'+rowid+'_declaredLicenses').val().split(",");

                result.forEach(function(cur,idx){
                    if(cur != ""){
                        var mult = "<span class=\"btnMulti\" style='margin-bottom:2px;'><span class=\"btnLicenseShow\" ondblclick='com_fn.showLicenseInfo(this)'>" + cur + "</span><button onclick='fn.removeDOM(this.parentNode)'>x</button></span><br/>";

                        $('#'+rowid+'_declaredLicensesBtn').append(mult);
                    }
                });

                // remove declaredLicenses input boxes
                $('#'+rowid+'_declaredLicenses').val("");

                // focusing
                var nextCol = OssBulkGridUtils.getGrid().jqGrid('getGridParam', 'colModel')[iCol].name
                var nextRow = rowid
                $('#'+nextRow+"_"+nextCol).focus();
            },
            multiselect: true,
            // beforeSelectRow: function(rowid, e) {
            //     var $self = $(this), iCol, cm,
            //         $td = $(e.target).closest("tr.jqgrow>td"),
            //         $tr = $td.closest("tr.jqgrow"),
            //         p = $self.jqGrid("getGridParam");
            //
            //     if ($(e.target).is("input[type=checkbox]") && $td.length > 0) {
            //         iCol = $.jgrid.getCellIndex($td[0]);
            //         cm = p.colModel[iCol];
            //         if (cm != null && cm.name === "cb") {
            //             // multiselect checkbox is clicked
            //             $self.jqGrid("setSelection", $tr.attr("id"), true ,e);
            //         }
            //     }
            // }
        });

        var accept1 = '';

        //checking for allowed extensions (xlsx, xls, xlsm)
        <c:forEach var="file" items="${ct:getCodes(ct:getConstDef('CD_FILE_ACCEPT'))}" varStatus="fileStatus">
        <c:if test="${file eq '11'}">
        accept1 = '${ct:getCodeExpString(ct:getConstDef("CD_FILE_ACCEPT"), file)}';
        </c:if>
        </c:forEach>

        // licenseNames auto complete
        commonAjax.getLicenseTags().success((data, status, headers, config) => {
            if(data != null && licenseNames == ""){
                var tag = "";
                data.forEach(function(obj){
                    if(obj!=null) {
                        tag ={
                            value : obj.shortIdentifier.length > 0 ? obj.shortIdentifier : obj.licenseName,
                            label : obj.licenseName + (obj.shortIdentifier.length > 0 ? (" (" + obj.shortIdentifier + ")") : ""),
                            type : obj.licenseType,
                            obligation : obj.obligation,
                            obligationChecks : obj.obligationChecks
                        }

                        licenseNames.push(tag);
                    }
                });
            }
        });

        $("#csvFile").uploadFile({
            url:'/oss/csvFile',
            multiple:false,
            dragDrop:true,
            fileName:'myfile',
            allowedTypes: accept1,
            sequential:true,
            sequentialCount:1,
            dynamicFormData: function(){
                var data ={ "registFileId" :$('#csvFileId').val(), "tabNm" : "BULK"};
                return data;
            },
            onSuccess:function(files,data,xhr,pd) {
                if (data['res'] == true){
                    fn.addRowsFromExcelImport(data['value']);
                }
                else if(data['res'] == false){
                    showErrorMsg();
                } else {
                    if (data['limitCheck'] == null) {
                        showErrorMsg();
                    }
                }
            }
        });
    });
    var fn = {
        downloadBulkSample : function(type){
            var logiPath = "/sample/FOSSLight-OSS-Bulk-Sample.xls";
            var fileName = "FOSSLight-OSS-Bulk-Sample.xls";

            location.href = '<c:url value="/partner/sampleDownload?fileName='+fileName+'&logiPath='+logiPath+'"/>';
        },

        /**
         * import excel requested datas
         */
        addRowsFromExcelImport: (datas) => {
            OssBulkGridUtils.addNewRows(datas.map(data => data.oss));
        },

        /**
         * Update grid after bulk save
         */
        checkLoaded: (datas) => {
            datas.forEach(data => {
                // update status message
                OssBulkGridUtils.updateCell(data.gridId, "status", data.status)
            });
        },

        /**
         * convert commaed string to array
         * "1,2,3" -> ["1", "2", "3"]
         */
        stringToArray: (string) => {
            if (!string || /^\s*$/.test(string))
                return [];

            return string.split(",").filter(str => (str != ""));
        },

        /**
         * dom remover
         */
        removeDOM: (dom) => {
            dom.remove();
        }
    }

    const OssBulkGridUtils = (function(gridDocumentId) {
        const grid = $(gridDocumentId);
        let lastSelected = null;

        return {
            getGrid: function() {
                return $(grid);
            },

            reloadGrid: function() {
                grid.trigger('reloadGrid');
            },

            getRow: function(gridId) {
                return grid.jqGrid("getRowData", gridId)
            },

            getAllRows: function() {
                return grid.jqGrid("getRowData");
            },

            getSelectedRows: function() {
                const gridIds = grid.jqGrid('getGridParam', 'selarrrow');
                return gridIds.map(id => this.getRow(id));
            },

            updateCell: function(gridId, column, value){
                grid.jqGrid("setCell", gridId, column, value);
            },

            newGridID: function(){
                return $.jgrid.randId();
            },

            addNewRow: function(newRow) {
                newRow.gridId = this.newGridID();
                grid.jqGrid('addRowData', newRow.gridId, newRow);
            },

            addNewRows: function(newRows) {
                newRows.forEach(row => this.addNewRow(row));
            },

            editRow: function(gridId) {
                this.saveLastEditedRow();

                lastSelected = gridId;
                grid.jqGrid('editRow', gridId);
            },

            saveRow: function(gridId) {
                const row = this.getRow(gridId);
                const declaredLicenses = row.declaredLicenses
                    .replace(/(<([^>]+)>)/ig, ",").split(",").reduce(function(arr, cur){
                    if(cur.toUpperCase() != "X" && cur != ""){
                        arr.push(cur);
                    }
                    return arr;
                }, []).join(",");

                this.updateCell(gridId, "declaredLicenses", declaredLicenses);
                grid.jqGrid('saveRow', gridId, {url: 'clientArray'});
            },

            saveLastEditedRow: function() {
                if(lastSelected)
                    this.saveRow(lastSelected);
            },

            bulkSaveRequestData: function() {
                this.saveLastEditedRow();

                return this.getSelectedRows().map(row => {
                    const res = {...row};

                    delete res.status;
                    res.declaredLicenses = fn.stringToArray(res.declaredLicenses);
                    res.detectedLicenses = fn.stringToArray(res.detectedLicenses);
                    res.ossNicknames = fn.stringToArray(res.ossNicknames);

                    return res;
                });
            }
        }
    })(grid);

    const OssBulkGridEventHandlers = {
        autoAddDeclaredLicenseDoms: (e) => {
            var rowid = (e.id).split('_')[0];
            var mult = null;
            var multText = null;

            if (mult == null && "" != e.value) {
                mult = "<span class=\"btnMulti\" style='margin-bottom:2px;'><span class=\"btnLicenseShow\" ondblclick='com_fn.showLicenseInfo(this)'>" + e.value + "</span><button onclick='com_fn.deleteLicenseRenewal(this)'>x</button></span><br/>";
                multText = e.value;
            }

            var rowLicenseNames = [];
            $('#' + rowid + '_declaredLicensesBtn').find('.btnLicenseShow').each(function (i, item) {
                rowLicenseNames.push($(this).text());
            });

            if (multText != null) {
                if (rowLicenseNames.length > 0) {
                    var duplicateFlag = false;
                    for (var i in rowLicenseNames) {
                        if (multText == rowLicenseNames[i]) {
                            duplicateFlag = true;
                            break;
                        }
                    }

                    if (!duplicateFlag) {
                        $('#' + rowid + '_declaredLicensesBtn').append(mult);
                    }
                } else {
                    $('#' + rowid + '_declaredLicensesBtn').append(mult);
                }
            }

            $('#' + rowid + '_declaredLicenses').val("");
        }
    }
</script>
